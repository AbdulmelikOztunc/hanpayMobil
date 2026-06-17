import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/features/admin/data/admin_repository.dart';
import 'package:hanpay_mobil/features/transfers/presentation/agent_transfer_detail_screen.dart';
import 'package:hanpay_mobil/shared/models/admin_models.dart';
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
                itemBuilder: (context, index) => _RequestCard(item: items[index], ref: ref),
              ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.item, required this.ref});
  final AdminRequestDto item;
  final WidgetRef ref;

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
            if (item.reason != null) Text(item.reason!),
            if (item.requestedByName != null) Text('Talep eden: ${item.requestedByName}'),
            const SizedBox(height: 8),
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

final adminTransfersProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminRepositoryProvider).getTransfers(take: 100);
});

class AdminTransfersScreen extends ConsumerWidget {
  const AdminTransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminTransfersProvider);
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminTransfersProvider)),
      data: (rows) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminTransfersProvider),
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
                      trailing: Text(formatUsd(r.amount)),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AgentTransferDetailScreen(id: r.id),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
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
    return async.when(
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
              ),
            );
          },
        ),
      ),
    );
  }
}

final adminAgentDetailProvider = FutureProvider.autoDispose.family<AdminAgentDto, int>((ref, id) {
  return ref.watch(adminRepositoryProvider).getAgent(id);
});

class AdminAgentDetailScreen extends ConsumerWidget {
  const AdminAgentDetailScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAgentDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Acente detayı')),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminAgentDetailProvider(id))),
        data: (a) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(a.name, style: Theme.of(context).textTheme.headlineSmall),
            Text('Kod: ${a.code}'),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                StatCard(label: 'Bakiye', value: formatUsd(a.balance), icon: Icons.account_balance_wallet),
                if (a.creditLimit != null)
                  StatCard(label: 'Kredi limiti', value: formatUsd(a.creditLimit!), icon: Icons.credit_score),
                if (a.commissionRate != null)
                  StatCard(label: 'Komisyon', value: '${(a.commissionRate! * 100).toStringAsFixed(2)}%', icon: Icons.percent),
                StatCard(label: 'Durum', value: a.isActive ? 'Aktif' : 'Pasif', icon: Icons.info_outline),
              ],
            ),
          ],
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
    return async.when(
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
              ),
            );
          },
        ),
      ),
    );
  }
}

final adminDistributorDetailProvider =
    FutureProvider.autoDispose.family<AdminDistributorDto, int>((ref, id) {
  return ref.watch(adminRepositoryProvider).getDistributor(id);
});

class AdminDistributorDetailScreen extends ConsumerWidget {
  const AdminDistributorDetailScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminDistributorDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Dağıtıcı detayı')),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminDistributorDetailProvider(id))),
        data: (d) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(d.name, style: Theme.of(context).textTheme.headlineSmall),
            Text('Kod: ${d.code}'),
            if (d.stateName != null) Text('Eyalet: ${d.stateName}'),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.4,
              children: [
                StatCard(label: 'Bakiye', value: formatUsd(d.balance), icon: Icons.account_balance_wallet),
                StatCard(label: 'Durum', value: d.isActive ? 'Aktif' : 'Pasif', icon: Icons.info_outline),
              ],
            ),
          ],
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminUsersProvider);
    return async.when(
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
                trailing: Icon(u.isActive ? Icons.check_circle : Icons.block, color: u.isActive ? Colors.green : Colors.grey),
              ),
            );
          },
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

final adminRolesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminRepositoryProvider).getRoles();
});

class AdminRolesScreen extends ConsumerWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              children: r.permissions.map((p) => ListTile(title: Text(p))).toList(),
            ),
          );
        },
      ),
    );
  }
}

final adminCashboxProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminRepositoryProvider).getCashboxes();
});

class AdminCashboxScreen extends ConsumerWidget {
  const AdminCashboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCashboxProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminCashboxProvider)),
      data: (data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            ],
          ),
          const SizedBox(height: 16),
          Text('Kullanıcı kasaları', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...data.userCashboxes.map(
            (u) => Card(
              child: ListTile(
                title: Text(u.fullName),
                subtitle: Text('${u.email} · ${u.role}'),
                trailing: Text(formatUsd(u.balance)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final adminPrimRecordsProvider = FutureProvider.autoDispose((ref) {
  final now = DateTime.now();
  return ref.watch(adminRepositoryProvider).getAllPrims(year: now.year, month: now.month);
});

class AdminPrimRecordsScreen extends ConsumerWidget {
  const AdminPrimRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPrimRecordsProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminPrimRecordsProvider)),
      data: (rows) => ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final r = rows[index];
          return Card(
            child: ListTile(
              title: Text('#${r.transferNumber}'),
              subtitle: Text(r.distributorName ?? '-'),
              trailing: Text(formatUsd(r.primAmount)),
            ),
          );
        },
      ),
    );
  }
}

final adminPrimPackagesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminRepositoryProvider).getPrimPackages();
});

class AdminPrimPackagesScreen extends ConsumerWidget {
  const AdminPrimPackagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPrimPackagesProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminPrimPackagesProvider)),
      data: (rows) => ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final p = rows[index];
          return Card(
            child: ListTile(
              title: Text(p.name),
              subtitle: Text(p.distributorName ?? '-'),
              trailing: Icon(p.isActive ? Icons.check_circle : Icons.pause_circle, color: p.isActive ? Colors.green : Colors.grey),
            ),
          );
        },
      ),
    );
  }
}

class AdminCentralCashboxScreen extends ConsumerWidget {
  const AdminCentralCashboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const AdminCashboxScreen();
}
