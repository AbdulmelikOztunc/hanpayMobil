import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/features/admin/data/admin_repository.dart';
import 'package:hanpay_mobil/features/admin/presentation/admin_screens.dart';
import 'package:hanpay_mobil/shared/models/user_model.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';

final adminUserDetailProvider = FutureProvider.autoDispose.family<AppUserDto, int>((ref, id) {
  return ref.watch(adminRepositoryProvider).getUser(id);
});

class AdminUserDetailScreen extends ConsumerWidget {
  const AdminUserDetailScreen({super.key, required this.id});
  final int id;

  Future<void> _edit(BuildContext context, WidgetRef ref, AppUserDto user) async {
    final nameCtrl = TextEditingController(text: user.fullName);
    var role = user.role;
    var isActive = user.isActive;
    int? agentId = user.agentId;
    int? distributorId = user.distributorId;

    final agents = await ref.read(adminRepositoryProvider).getAgents();
    final distributors = await ref.read(adminRepositoryProvider).getDistributors();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Kullanıcı düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ad soyad')),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'AgentUser', child: Text('AgentUser')),
                    DropdownMenuItem(value: 'AgentManager', child: Text('AgentManager')),
                    DropdownMenuItem(value: 'DistributorUser', child: Text('DistributorUser')),
                    DropdownMenuItem(value: 'DistributorManager', child: Text('DistributorManager')),
                    DropdownMenuItem(value: 'AssistantAdmin', child: Text('AssistantAdmin')),
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setState(() => role = v ?? role),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                ),
                if (agents.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    initialValue: agentId,
                    decoration: const InputDecoration(labelText: 'Acente'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Atanmamış')),
                      ...agents.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                    ],
                    onChanged: (v) => setState(() {
                      agentId = v;
                      if (v != null) distributorId = null;
                    }),
                  ),
                if (distributors.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    initialValue: distributorId,
                    decoration: const InputDecoration(labelText: 'Dağıtıcı'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Atanmamış')),
                      ...distributors.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                    ],
                    onChanged: (v) => setState(() {
                      distributorId = v;
                      if (v != null) agentId = null;
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
          ],
        ),
      ),
    );
    final fullName = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (ok != true || fullName.isEmpty) return;

    try {
      await ref.read(adminRepositoryProvider).updateUser(id, {
        'fullName': fullName,
        'role': role,
        'isActive': isActive,
      });
      if (agentId != user.agentId || distributorId != user.distributorId) {
        if (agentId == null && distributorId == null) {
          await ref.read(adminRepositoryProvider).unassignUser(id);
        } else {
          await ref.read(adminRepositoryProvider).assignUser(
                id,
                agentId: agentId,
                distributorId: distributorId,
              );
        }
      }
      ref.invalidate(adminUserDetailProvider(id));
      ref.invalidate(adminUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı güncellendi')));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullanıcıyı sil'),
        content: const Text('Bu kullanıcıyı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteUser(id);
      ref.invalidate(adminUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı silindi')));
        context.pop();
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminUserDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı detayı')),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminUserDetailProvider(id))),
        data: (user) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(user.email),
            Text('Rol: ${user.role}'),
            Text('Durum: ${user.isActive ? 'Aktif' : 'Pasif'}'),
            if (user.agentName != null) Text('Acente: ${user.agentName}'),
            if (user.distributorName != null) Text('Dağıtıcı: ${user.distributorName}'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _edit(context, ref, user),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Düzenle / ata'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _delete(context, ref),
              icon: const Icon(Icons.delete_outline),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              label: const Text('Sil'),
            ),
          ],
        ),
      ),
    );
  }
}
