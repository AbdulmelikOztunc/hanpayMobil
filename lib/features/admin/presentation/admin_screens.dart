import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/features/admin/data/admin_repository.dart';
import 'package:hanpay_mobil/features/admin/presentation/admin_partner_dialogs.dart';
import 'package:hanpay_mobil/features/transfers/presentation/agent_transfer_detail_screen.dart';
import 'package:hanpay_mobil/shared/models/admin_models.dart';
import 'package:hanpay_mobil/shared/models/state_model.dart';
import 'package:hanpay_mobil/shared/utils/balance_ledger_export.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/stat_card.dart';
import 'package:intl/intl.dart';

final adminRequestsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminRepositoryProvider).getRequests();
});

class AdminRequestsScreen extends ConsumerWidget {
  const AdminRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminRequestsProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminRequestsProvider)),
      data: (items) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminRequestsProvider),
        child: items.isEmpty
            ? ListView(children: const [SizedBox(height: 120), Center(child: Text('Bekleyen talep yok.'))])
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _RequestCard(item: items[index]),
              ),
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.item});
  final AdminRequestDto item;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  AdminRequestDto get item => widget.item;

  Future<void> _resolveCancellation() async {
    final noteCtrl = TextEditingController();
    var action = 'cancel';
    var commissionMode = 1;
    StateDto? targetState;
    final states = await ref.read(adminRepositoryProvider).getStates();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('İptal talebini çöz'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'cancel', label: Text('İptal et')),
                    ButtonSegment(value: 'reassign', label: Text('Yeniden ata')),
                  ],
                  selected: {action},
                  onSelectionChanged: (v) => setDialogState(() => action = v.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Admin notu'),
                  maxLines: 2,
                ),
                if (action == 'cancel' && (item.netCommissionUsd ?? 0) > 0) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: commissionMode,
                    decoration: const InputDecoration(labelText: 'Komisyon'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Acenteye iade')),
                      DropdownMenuItem(value: 2, child: Text('Platformda bırak')),
                    ],
                    onChanged: (v) => setDialogState(() => commissionMode = v ?? 1),
                  ),
                ],
                if (action == 'reassign' && states.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<StateDto>(
                    value: targetState,
                    decoration: const InputDecoration(labelText: 'Hedef eyalet'),
                    items: states
                        .where((s) => s.id != item.transferStateId)
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => targetState = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
          ],
        ),
      ),
    );
    final note = noteCtrl.text.trim();
    noteCtrl.dispose();
    if (ok != true || note.isEmpty) return;

    try {
      await ref.read(adminRepositoryProvider).resolveTransferCancellationRequest(
            item.id,
            action: action,
            adminNote: note,
            commissionSettlement: action == 'cancel' ? commissionMode : null,
            targetStateId: action == 'reassign' ? targetState?.id : null,
          );
      ref.invalidate(adminRequestsProvider);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.type} · ${item.status}', style: Theme.of(context).textTheme.titleMedium),
            if (item.transferNumber != null) Text('Havale: #${item.transferNumber}'),
            if (item.transferState != null) Text('Eyalet: ${item.transferState}'),
            if (item.reason != null) Text(item.reason!),
            if (item.requestedByName != null) Text('Talep eden: ${item.requestedByName}'),
            const SizedBox(height: 8),
            if (item.isCancellationRequest && item.status.toLowerCase() != 'approved')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.tonal(
                  onPressed: _resolveCancellation,
                  child: const Text('İptal talebini çöz'),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        await ref.read(adminRepositoryProvider).rejectRequest(item.id);
                        ref.invalidate(adminRequestsProvider);
                      } on ApiException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      }
                    },
                    child: const Text('Reddet'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      try {
                        await ref.read(adminRepositoryProvider).approveRequest(item.id);
                        ref.invalidate(adminRequestsProvider);
                      } on ApiException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      }
                    },
                    child: const Text('Onayla'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final adminTransfersProvider = FutureProvider.autoDispose
    .family<List<AdminTransferRow>, ({String? search, String? status, String? fromUtc, String? toUtc})>(
  (ref, filters) {
    return ref.watch(adminRepositoryProvider).getTransfers(
          search: filters.search,
          status: filters.status,
          fromUtc: filters.fromUtc,
          toUtc: filters.toUtc,
          take: 100,
        );
  },
);

class AdminTransfersScreen extends ConsumerStatefulWidget {
  const AdminTransfersScreen({super.key});

  @override
  ConsumerState<AdminTransfersScreen> createState() => _AdminTransfersScreenState();
}

class _AdminTransfersScreenState extends ConsumerState<AdminTransfersScreen> {
  final _searchCtrl = TextEditingController();
  String? _status;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  ({String? search, String? status, String? fromUtc, String? toUtc}) get _filters => (
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        status: _status,
        fromUtc: _fromDate?.toUtc().toIso8601String(),
        toUtc: _toDate?.toUtc().toIso8601String(),
      );

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (range != null) {
      setState(() {
        _fromDate = range.start;
        _toDate = range.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = _filters;
    final async = ref.watch(adminTransfersProvider(filters));
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: 'Ara',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => setState(() {}),
                  ),
                ),
                onSubmitted: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Durum'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tümü')),
                        DropdownMenuItem(value: 'Pending', child: Text('Bekliyor')),
                        DropdownMenuItem(value: 'Paid', child: Text('Ödendi')),
                        DropdownMenuItem(value: 'Cancelled', child: Text('İptal')),
                        DropdownMenuItem(value: 'InProgress', child: Text('Devam ediyor')),
                      ],
                      onChanged: (v) => setState(() => _status = v),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tarih aralığı',
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range),
                  ),
                ],
              ),
              if (_fromDate != null && _toDate != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _fromDate = null;
                      _toDate = null;
                    }),
                    child: Text(
                      '${DateFormat('dd.MM.yyyy').format(_fromDate!)} - ${DateFormat('dd.MM.yyyy').format(_toDate!)} (temizle)',
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const LoadingView(),
            error: (e, _) =>
                ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminTransfersProvider(filters))),
            data: (rows) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminTransfersProvider(filters)),
              child: rows.isEmpty
                  ? ListView(children: const [SizedBox(height: 120), Center(child: Text('Transfer yok.'))])
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final r = rows[index];
                        return Card(
                          child: ListTile(
                            title: Text('#${r.transferNumber}'),
                            subtitle: Text(
                              '${r.agentName ?? '-'} · ${r.receiverFullName ?? '-'}\n${dateFmt.format(r.createdAt.toLocal())}',
                            ),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatUsd(r.amount)),
                                if (canAdminCancelTransfer(r.status))
                                  TextButton(
                                    onPressed: () async {
                                      final cancelled = await showAdminCancelTransferDialog(
                                        context,
                                        ref,
                                        transferId: r.id,
                                      );
                                      if (cancelled) {
                                        ref.invalidate(adminTransfersProvider(filters));
                                      }
                                    },
                                    child: const Text('İptal'),
                                  ),
                              ],
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AgentTransferDetailScreen(id: r.id, allowAdminCancel: true),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

final adminAgentsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminRepositoryProvider).getAgents();
});

class AdminAgentsScreen extends ConsumerWidget {
  const AdminAgentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAgentsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showCreateAgentDialog(context, ref);
          ref.invalidate(adminAgentsProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminAgentsProvider)),
        data: (agents) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminAgentsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: agents.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final a = agents[index];
              return Card(
                child: ListTile(
                  title: Text(a.name),
                  subtitle: Text('${a.code} · ${a.isActive ? 'Aktif' : 'Pasif'}'),
                  trailing: Text(formatUsd(a.balance)),
                  onTap: () => context.push('/admin/agents/${a.id}'),
                  onLongPress: () async {
                    await showEditAgentDialog(context, ref, a);
                    ref.invalidate(adminAgentsProvider);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

final adminDistributorsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminRepositoryProvider).getDistributors();
});

class AdminDistributorsScreen extends ConsumerWidget {
  const AdminDistributorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminDistributorsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showCreateDistributorDialog(context, ref);
          ref.invalidate(adminDistributorsProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminDistributorsProvider)),
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminDistributorsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final d = items[index];
              return Card(
                child: ListTile(
                  title: Text(d.name),
                  subtitle: Text('${d.code} · ${d.stateName ?? '-'}'),
                  trailing: Text(formatUsd(d.balance)),
                  onTap: () => context.push('/admin/distributors/${d.id}'),
                  onLongPress: () async {
                    await showEditDistributorDialog(context, ref, d);
                    ref.invalidate(adminDistributorsProvider);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


final adminUsersProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminRepositoryProvider).getUsers();
});

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  Future<void> _createUser(BuildContext context, WidgetRef ref) async {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    var role = 'AgentUser';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Kullanıcı oluştur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'E-posta')),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ad soyad')),
                TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Şifre')),
                DropdownButtonFormField<String>(
                  value: role,
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
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oluştur')),
          ],
        ),
      ),
    );
    final email = emailCtrl.text.trim();
    final fullName = nameCtrl.text.trim();
    final password = passCtrl.text;
    emailCtrl.dispose();
    nameCtrl.dispose();
    passCtrl.dispose();
    if (ok != true || email.isEmpty || password.length < 6) return;
    try {
      await ref.read(adminRepositoryProvider).createUser({
        'email': email,
        'fullName': fullName,
        'password': password,
        'role': role,
      });
      ref.invalidate(adminUsersProvider);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminUsersProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createUser(context, ref),
        child: const Icon(Icons.person_add),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminUsersProvider)),
        data: (users) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminUsersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final u = users[index];
              return Card(
                child: ListTile(
                  title: Text(u.fullName),
                  subtitle: Text('${u.email}\n${u.role}'),
                  isThreeLine: true,
                  trailing: Icon(
                    u.isActive ? Icons.check_circle : Icons.block,
                    color: u.isActive ? Colors.green : Colors.grey,
                  ),
                  onTap: () => context.push('/admin/users/${u.id}'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

final adminStatesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminRepositoryProvider).getStates();
});

class AdminStatesScreen extends ConsumerStatefulWidget {
  const AdminStatesScreen({super.key});

  @override
  ConsumerState<AdminStatesScreen> createState() => _AdminStatesScreenState();
}

class _AdminStatesScreenState extends ConsumerState<AdminStatesScreen> {
  Future<void> _addState() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eyalet ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ad')),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Kod')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).createState(name: nameCtrl.text.trim(), code: codeCtrl.text.trim());
      ref.invalidate(adminStatesProvider);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _editState(StateDto state) async {
    final nameCtrl = TextEditingController(text: state.name);
    final codeCtrl = TextEditingController(text: state.code);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eyalet düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ad')),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Kod')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
        ],
      ),
    );
    final name = nameCtrl.text.trim();
    final code = codeCtrl.text.trim();
    nameCtrl.dispose();
    codeCtrl.dispose();
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).updateState(state.id, name: name, code: code);
      ref.invalidate(adminStatesProvider);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminStatesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: _addState, child: const Icon(Icons.add)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminStatesProvider)),
        data: (states) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminStatesProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: states.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final s = states[index];
              return Card(
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Text(s.code),
                  onTap: () => _editState(s),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref.read(adminRepositoryProvider).deleteState(s.id);
                      ref.invalidate(adminStatesProvider);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

final adminSettingsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final min = await repo.getMinimumTransferUsd();
  final days = await repo.getReceiptRetentionDays();
  return (min, days);
});

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final minCtrl = TextEditingController();
  final daysCtrl = TextEditingController();

  @override
  void dispose() {
    minCtrl.dispose();
    daysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminSettingsProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminSettingsProvider)),
      data: (settings) {
        if (minCtrl.text.isEmpty) {
          minCtrl.text = settings.$1.toString();
          daysCtrl.text = settings.$2.toString();
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: minCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Minimum transfer (USD)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: daysCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Makbuz saklama (gün)'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                try {
                  final repo = ref.read(adminRepositoryProvider);
                  await repo.updateMinimumTransferUsd(double.parse(minCtrl.text.replaceAll(',', '.')));
                  await repo.updateReceiptRetentionDays(int.parse(daysCtrl.text));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ayarlar kaydedildi')));
                  }
                } on ApiException catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }
}

final adminRolesProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final roles = await repo.getRoles();
  final matrix = await repo.getPermissionsMatrix();
  return roles
      .map(
        (r) => RoleDto(
          id: r.id,
          name: r.name,
          permissions: matrix[r.name]?.isNotEmpty == true ? matrix[r.name]! : r.permissions,
        ),
      )
      .toList();
});

class AdminRolesScreen extends ConsumerStatefulWidget {
  const AdminRolesScreen({super.key});

  @override
  ConsumerState<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends ConsumerState<AdminRolesScreen> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminRolesProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminRolesProvider)),
      data: (roles) => ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: roles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final r = roles[index];
          return Card(
            child: ExpansionTile(
              title: Text(r.name),
              subtitle: Text('${r.permissions.length} izin'),
              children: [
                ...r.permissions.map((p) => ListTile(title: Text(p))),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlinedButton(
                    onPressed: () async {
                      final catalog = await ref.read(adminRepositoryProvider).getPermissionsCatalog();
                      final selected = {...r.permissions};
                      final saved = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => StatefulBuilder(
                          builder: (context, setDialogState) => AlertDialog(
                            title: Text('${r.name} izinleri'),
                            content: SizedBox(
                              width: double.maxFinite,
                              height: 360,
                              child: ListView(
                                children: catalog
                                    .map(
                                      (p) => CheckboxListTile(
                                        value: selected.contains(p),
                                        title: Text(p, style: const TextStyle(fontSize: 13)),
                                        onChanged: (v) => setDialogState(() {
                                          if (v == true) {
                                            selected.add(p);
                                          } else {
                                            selected.remove(p);
                                          }
                                        }),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
                            ],
                          ),
                        ),
                      );
                      if (saved != true) return;
                      try {
                        await ref
                            .read(adminRepositoryProvider)
                            .updateRolePermissions(r.id, selected.toList());
                        ref.invalidate(adminRolesProvider);
                      } on ApiException catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      }
                    },
                    child: const Text('İzinleri düzenle'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

final adminCashboxProvider = FutureProvider.autoDispose
    .family<CashboxesSummary, ({String? fromUtc, String? toUtc})>((ref, filters) {
  return ref.watch(adminRepositoryProvider).getCashboxes(
        fromUtc: filters.fromUtc,
        toUtc: filters.toUtc,
      );
});

class AdminCashboxScreen extends ConsumerStatefulWidget {
  const AdminCashboxScreen({super.key});

  @override
  ConsumerState<AdminCashboxScreen> createState() => _AdminCashboxScreenState();
}

class _AdminCashboxScreenState extends ConsumerState<AdminCashboxScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  ({String? fromUtc, String? toUtc}) get _filters => (
        fromUtc: _fromDate?.toUtc().toIso8601String(),
        toUtc: _toDate?.toUtc().toIso8601String(),
      );

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (range != null) {
      setState(() {
        _fromDate = range.start;
        _toDate = range.end;
      });
    }
  }

  Future<void> _manualMovement(BuildContext context, WidgetRef ref, UserCashboxRow user) async {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var direction = 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${user.fullName} — manuel hareket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('Giriş')),
                  ButtonSegment(value: 2, label: Text('Çıkış')),
                ],
                selected: {direction},
                onSelectionChanged: (v) => setDialogState(() => direction = v.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Tutar (USD)'),
              ),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Açıklama')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
          ],
        ),
      ),
    );
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final description = descCtrl.text.trim();
    amountCtrl.dispose();
    descCtrl.dispose();
    if (ok != true || amount <= 0 || description.isEmpty) return;
    try {
      await ref.read(adminRepositoryProvider).recordUserManualMovement(
            user.userId,
            amount: amount,
            description: description,
            direction: direction,
          );
      ref.invalidate(adminCashboxProvider(_filters));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _exportLedger(CashboxesSummary data) async {
    final rows = data.centralDayEntries
        .where((e) => !e.isReportingOnly)
        .map(
          (e) => BalanceLedgerExportRow(
            date: e.createdAt,
            title: e.description.isEmpty ? (e.isCredit ? 'Giriş' : 'Çıkış') : e.description,
            subtitle: e.counterparty,
            amount: e.amount,
            isCredit: e.isCredit,
          ),
        )
        .toList();
    await shareBalanceLedgerCsv(
      filenamePrefix: 'merkez-kasa',
      openingBalance: data.openingBalance ?? data.centralBalance,
      closingBalance: data.centralBalance,
      rows: rows,
      from: _fromDate,
      to: _toDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = _filters;
    final async = ref.watch(adminCashboxProvider(filters));
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminCashboxProvider(filters))),
      data: (data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _fromDate != null && _toDate != null
                        ? '${DateFormat('dd.MM.yyyy').format(_fromDate!)} - ${DateFormat('dd.MM.yyyy').format(_toDate!)}'
                        : 'Tarih aralığı seç',
                  ),
                ),
              ),
              if (_fromDate != null)
                IconButton(
                  onPressed: () => setState(() {
                    _fromDate = null;
                    _toDate = null;
                  }),
                  icon: const Icon(Icons.clear),
                ),
              IconButton(
                tooltip: 'Excel/CSV indir',
                onPressed: data.centralDayEntries.isEmpty ? null : () => _exportLedger(data),
                icon: const Icon(Icons.download),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              StatCard(label: 'Merkez kasa', value: formatUsd(data.centralBalance), icon: Icons.account_balance),
              StatCard(label: 'Net sistem varlığı', value: formatUsd(data.netSystemAsset), icon: Icons.analytics),
              if (data.totalCommissionEarned > 0)
                StatCard(
                  label: 'Net komisyon',
                  value: formatUsd(data.totalCommissionEarned),
                  icon: Icons.percent,
                ),
              if (data.openingBalance != null)
                StatCard(label: 'Devir', value: formatUsd(data.openingBalance!), icon: Icons.history),
            ],
          ),
          if (data.centralDayEntries.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Merkez kasa hareketleri', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...data.centralDayEntries.map(
              (e) => Card(
                child: ListTile(
                  title: Text(e.description.isEmpty ? e.counterparty : e.description),
                  subtitle: Text(dateFmt.format(e.createdAt.toLocal())),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${e.isCredit ? '+' : '-'}${formatUsd(e.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: e.isCredit ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      if (e.isReportingOnly)
                        const Text('Rapor', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Kullanıcı kasaları', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...data.userCashboxes.map(
            (u) => Card(
              child: ListTile(
                title: Text(u.fullName),
                subtitle: Text('${u.email} · ${u.role}'),
                trailing: Text(formatUsd(u.balance)),
                onTap: () => _manualMovement(context, ref, u),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminCentralCashboxScreen extends ConsumerWidget {
  const AdminCentralCashboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const AdminCashboxScreen();
}
