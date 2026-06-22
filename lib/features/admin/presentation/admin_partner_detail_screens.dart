import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/features/admin/data/admin_repository.dart';
import 'package:hanpay_mobil/features/admin/presentation/admin_partner_dialogs.dart';
import 'package:hanpay_mobil/features/admin/presentation/admin_screens.dart';
import 'package:hanpay_mobil/features/agent/data/agent_repository.dart';
import 'package:hanpay_mobil/features/transfers/presentation/agent_transfer_detail_screen.dart';
import 'package:hanpay_mobil/shared/models/admin_models.dart';
import 'package:hanpay_mobil/shared/models/balance_models.dart';
import 'package:hanpay_mobil/shared/models/user_model.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/stat_card.dart';
import 'package:hanpay_mobil/shared/widgets/transfer_status_chip.dart';
import 'package:intl/intl.dart';

final adminAgentDetailProvider = FutureProvider.autoDispose.family<AdminAgentDto, int>((ref, id) {
  return ref.watch(adminRepositoryProvider).getAgent(id);
});

final adminAgentSummaryProvider = FutureProvider.autoDispose.family<AgentDetailStatistics?, int>((ref, id) {
  return ref.watch(adminRepositoryProvider).getAgentSummary(id);
});

final adminAgentTransactionsProvider =
    FutureProvider.autoDispose.family<List<AgentTransactionRow>, int>((ref, id) {
  return ref.watch(adminRepositoryProvider).getAgentTransactions(id);
});

final adminDistributorDetailProvider =
    FutureProvider.autoDispose.family<AdminDistributorDto, int>((ref, id) {
  return ref.watch(adminRepositoryProvider).getDistributor(id);
});

final adminDistributorBalanceHistoryProvider =
    FutureProvider.autoDispose.family<List<AgentTransactionRow>, int>((ref, id) {
  return ref.watch(adminRepositoryProvider).getDistributorBalanceHistory(id);
});

final adminDistributorEarnedPrimsProvider =
    FutureProvider.autoDispose.family<List<DistributorPrimRow>?, int>((ref, id) {
  return ref.watch(adminRepositoryProvider).getDistributorEarnedPrims(id);
});

class AdminAgentDetailScreen extends ConsumerWidget {
  const AdminAgentDetailScreen({super.key, required this.id});
  final int id;

  Future<void> _reactivate(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(adminRepositoryProvider).reactivateAgent(id);
      ref.invalidate(adminAgentDetailProvider(id));
      ref.invalidate(adminAgentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acente yeniden aktifleştirildi.')));
      }
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acenteyi sil'),
        content: const Text('Bu acenteyi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteAgent(id);
      ref.invalidate(adminAgentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acente silindi.')));
        context.pop();
      }
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _adjustBalance(BuildContext context, WidgetRef ref, {required bool credit}) async {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(credit ? 'Bakiye yükle' : 'Bakiye düş'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Uygula')),
        ],
      ),
    );
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final description = descCtrl.text.trim();
    amountCtrl.dispose();
    descCtrl.dispose();
    if (ok != true || amount <= 0) return;
    try {
      if (credit) {
        await ref.read(agentRepositoryProvider).creditAgentBalance(id, amount: amount, description: description);
      } else {
        await ref.read(agentRepositoryProvider).debitAgentBalance(id, amount: amount, description: description);
      }
      ref.invalidate(adminAgentDetailProvider(id));
      ref.invalidate(adminAgentTransactionsProvider(id));
      ref.invalidate(adminAgentsProvider);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAgentDetailProvider(id));
    return async.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminAgentDetailProvider(id))),
      ),
      data: (agent) => DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: Text(agent.name),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Özet'),
                Tab(text: 'Talepler'),
                Tab(text: 'Transferler'),
                Tab(text: 'Kullanıcılar'),
                Tab(text: 'Bakiye'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Düzenle',
                onPressed: () async {
                  await showEditAgentDialog(context, ref, agent);
                  ref.invalidate(adminAgentDetailProvider(id));
                  ref.invalidate(adminAgentsProvider);
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Sil',
                onPressed: () => _delete(context, ref),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: TabBarView(
            children: [
              _AgentOverviewTab(
                agent: agent,
                agentId: id,
                onCredit: () => _adjustBalance(context, ref, credit: true),
                onDebit: () => _adjustBalance(context, ref, credit: false),
                onReactivate: () => _reactivate(context, ref),
              ),
              _PartnerRequestsTab(agentId: id),
              _PartnerTransfersTab(agentId: id),
              _PartnerUsersTab(agentId: id),
              _AgentBalanceTab(agentId: id),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentOverviewTab extends ConsumerWidget {
  const _AgentOverviewTab({
    required this.agent,
    required this.agentId,
    required this.onCredit,
    required this.onDebit,
    required this.onReactivate,
  });

  final AdminAgentDto agent;
  final int agentId;
  final VoidCallback onCredit;
  final VoidCallback onDebit;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(adminAgentSummaryProvider(agentId));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Kod: ${agent.code}', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            StatCard(label: 'Bakiye', value: formatUsd(agent.balance), icon: Icons.account_balance_wallet),
            if (agent.creditLimit != null)
              StatCard(label: 'Kredi limiti', value: formatUsd(agent.creditLimit!), icon: Icons.credit_score),
            if (agent.commissionRate != null)
              StatCard(label: 'Komisyon', value: '${(agent.commissionRate! * 100).toStringAsFixed(2)}%', icon: Icons.percent),
            StatCard(label: 'Durum', value: agent.isActive ? 'Aktif' : 'Pasif', icon: Icons.info_outline),
          ],
        ),
        summaryAsync.when(
          loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (stats) {
            if (stats == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text('İstatistikler', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    StatCard(label: 'Toplam transfer', value: '${stats.totalTransfers}', icon: Icons.swap_horiz),
                    StatCard(label: 'Toplam tutar', value: formatUsd(stats.totalAmount), icon: Icons.payments),
                    StatCard(label: 'Ödenen', value: '${stats.paidCount}', icon: Icons.check_circle_outline),
                    StatCard(label: 'Başarı oranı', value: '${stats.successRate.toStringAsFixed(1)}%', icon: Icons.trending_up),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: onCredit, child: const Text('Bakiye yükle'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: onDebit, child: const Text('Bakiye düş'))),
          ],
        ),
        if (!agent.isActive) ...[
          const SizedBox(height: 8),
          FilledButton(onPressed: onReactivate, child: const Text('Yeniden aktifleştir')),
        ],
      ],
    );
  }
}

class _AgentBalanceTab extends ConsumerWidget {
  const _AgentBalanceTab({required this.agentId});
  final int agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(adminAgentTransactionsProvider(agentId));
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');
    return txAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminAgentTransactionsProvider(agentId))),
      data: (items) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminAgentTransactionsProvider(agentId)),
        child: items.isEmpty
            ? ListView(children: const [SizedBox(height: 120), Center(child: Text('Kayıt yok.'))])
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final t = items[index];
                  return Card(
                    child: ListTile(
                      title: Text(formatUsd(t.amount)),
                      subtitle: Text('${t.transactionType}\n${t.description}\n${dateFmt.format(t.date.toLocal())}'),
                      isThreeLine: true,
                      trailing: Text(formatUsd(t.balanceAfter), style: const TextStyle(fontSize: 12)),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _PartnerRequestsTab extends ConsumerWidget {
  const _PartnerRequestsTab({this.agentId, this.distributorId});
  final int? agentId;
  final int? distributorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(adminRequestsProvider);
    final usersAsync = ref.watch(adminUsersProvider);
    final transfersAsync = ref.watch(adminTransfersProvider((search: null, status: null, fromUtc: null, toUtc: null)));

    return requestsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminRequestsProvider)),
      data: (requests) {
        return usersAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminUsersProvider)),
          data: (users) {
            return transfersAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminTransfersProvider((search: null, status: null, fromUtc: null, toUtc: null))),
              ),
              data: (transfers) {
                final partnerUserIds = _partnerUserIds(users, agentId: agentId, distributorId: distributorId);
                final partnerTransferIds = _partnerTransferIds(transfers, agentId: agentId, distributorId: distributorId);
                final filtered = requests.where((r) {
                  if (r.createdByUserId != null && partnerUserIds.contains(r.createdByUserId)) return true;
                  if (r.transferId != null && partnerTransferIds.contains(r.transferId)) return true;
                  return false;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Talep yok.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final r = filtered[index];
                    return Card(
                      child: ListTile(
                        title: Text('${r.type} · ${r.status}'),
                        subtitle: Text(
                          [
                            if (r.transferNumber != null) '#${r.transferNumber}',
                            if (r.requestedByName != null) r.requestedByName,
                            if (r.reason != null) r.reason,
                          ].whereType<String>().join('\n'),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Set<int> _partnerUserIds(List<AppUserDto> users, {int? agentId, int? distributorId}) {
    return users
        .where((u) {
          if (agentId != null) return u.agentId == agentId;
          if (distributorId != null) return u.distributorId == distributorId;
          return false;
        })
        .map((u) => u.id)
        .toSet();
  }

  Set<int> _partnerTransferIds(List<AdminTransferRow> transfers, {int? agentId, int? distributorId}) {
    if (agentId != null) {
      return transfers.where((t) => t.agentId == agentId).map((t) => t.id).toSet();
    }
    if (distributorId != null) {
      return transfers.where((t) => t.distributorId == distributorId).map((t) => t.id).toSet();
    }
    return transfers.map((t) => t.id).toSet();
  }
}

class _PartnerTransfersTab extends ConsumerWidget {
  const _PartnerTransfersTab({this.agentId, this.distributorId});
  final int? agentId;
  final int? distributorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminTransfersProvider((search: null, status: null, fromUtc: null, toUtc: null)));
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(adminTransfersProvider((search: null, status: null, fromUtc: null, toUtc: null))),
      ),
      data: (rows) {
        final filtered = rows.where((r) {
          if (agentId != null) return r.agentId == agentId;
          if (distributorId != null) return r.distributorId == distributorId;
          return true;
        }).toList();
        if (filtered.isEmpty) return const Center(child: Text('Transfer yok.'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final r = filtered[index];
            return Card(
              child: ListTile(
                title: Text('#${r.transferNumber}'),
                subtitle: Text('${r.receiverFullName ?? '-'}\n${dateFmt.format(r.createdAt.toLocal())}'),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatUsd(r.amount)),
                    TransferStatusChip(status: r.status),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AgentTransferDetailScreen(id: r.id, allowAdminCancel: true)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PartnerUsersTab extends ConsumerWidget {
  const _PartnerUsersTab({this.agentId, this.distributorId});
  final int? agentId;
  final int? distributorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminUsersProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminUsersProvider)),
      data: (users) {
        final filtered = users.where((u) {
          if (agentId != null) return u.agentId == agentId;
          if (distributorId != null) return u.distributorId == distributorId;
          return false;
        }).toList();
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Kullanıcı yok.'),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => context.push('/admin/users'),
                  child: const Text('Kullanıcı ata'),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final u = filtered[index];
            return Card(
              child: ListTile(
                title: Text(u.fullName),
                subtitle: Text('${u.email}\n${u.role}'),
                isThreeLine: true,
                trailing: Icon(u.isActive ? Icons.check_circle : Icons.block, color: u.isActive ? Colors.green : Colors.grey),
                onTap: () => context.push('/admin/users/${u.id}'),
              ),
            );
          },
        );
      },
    );
  }
}

class AdminDistributorDetailScreen extends ConsumerWidget {
  const AdminDistributorDetailScreen({super.key, required this.id});
  final int id;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dağıtıcıyı sil'),
        content: const Text('Bu dağıtıcıyı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteDistributor(id);
      ref.invalidate(adminDistributorsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dağıtıcı silindi.')));
        context.pop();
      }
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _adjustBalance(BuildContext context, WidgetRef ref, {required bool credit}) async {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(credit ? 'Bakiye yükle' : 'Bakiye düş'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Uygula')),
        ],
      ),
    );
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final description = descCtrl.text.trim();
    amountCtrl.dispose();
    descCtrl.dispose();
    if (ok != true || amount <= 0) return;
    try {
      if (credit) {
        await ref.read(adminRepositoryProvider).creditDistributorBalance(id, amount: amount, description: description);
      } else {
        await ref.read(adminRepositoryProvider).debitDistributorBalance(id, amount: amount, description: description);
      }
      ref.invalidate(adminDistributorDetailProvider(id));
      ref.invalidate(adminDistributorBalanceHistoryProvider(id));
      ref.invalidate(adminDistributorsProvider);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminDistributorDetailProvider(id));
    return async.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminDistributorDetailProvider(id))),
      ),
      data: (d) => DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: Text(d.name),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Özet'),
                Tab(text: 'Talepler'),
                Tab(text: 'Transferler'),
                Tab(text: 'Kullanıcılar'),
                Tab(text: 'Bakiye'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Düzenle',
                onPressed: () async {
                  await showEditDistributorDialog(context, ref, d);
                  ref.invalidate(adminDistributorDetailProvider(id));
                  ref.invalidate(adminDistributorsProvider);
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Sil',
                onPressed: () => _delete(context, ref),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: TabBarView(
            children: [
              _DistributorOverviewTab(
                distributor: d,
                onCredit: () => _adjustBalance(context, ref, credit: true),
                onDebit: () => _adjustBalance(context, ref, credit: false),
              ),
              _PartnerRequestsTab(distributorId: id),
              _PartnerTransfersTab(distributorId: id),
              _PartnerUsersTab(distributorId: id),
              _DistributorBalanceTab(distributorId: id),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistributorOverviewTab extends ConsumerWidget {
  const _DistributorOverviewTab({
    required this.distributor,
    required this.onCredit,
    required this.onDebit,
  });

  final AdminDistributorDto distributor;
  final VoidCallback onCredit;
  final VoidCallback onDebit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primsAsync = ref.watch(adminDistributorEarnedPrimsProvider(distributor.id));
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Kod: ${distributor.code}'),
        if (distributor.stateName != null) Text('Eyalet: ${distributor.stateName}'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          children: [
            StatCard(label: 'Bakiye', value: formatUsd(distributor.balance), icon: Icons.account_balance_wallet),
            StatCard(label: 'Durum', value: distributor.isActive ? 'Aktif' : 'Pasif', icon: Icons.info_outline),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: onCredit, child: const Text('Bakiye yükle'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: onDebit, child: const Text('Bakiye düş'))),
          ],
        ),
        const SizedBox(height: 24),
        Text('Son primler', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        primsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Primler yüklenemedi: $e'),
          data: (items) {
            if (items == null || items.isEmpty) return const Text('Prim kaydı yok.');
            return Column(
              children: items.take(5).map((p) => Card(
                child: ListTile(
                  title: Text(p.transferNumber),
                  subtitle: Text(dateFmt.format(p.earnedAt.toLocal())),
                  trailing: Text(formatUsd(p.primAmount)),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _DistributorBalanceTab extends ConsumerWidget {
  const _DistributorBalanceTab({required this.distributorId});
  final int distributorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(adminDistributorBalanceHistoryProvider(distributorId));
    final primsAsync = ref.watch(adminDistributorEarnedPrimsProvider(distributorId));
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Bakiye hareketleri', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        historyAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Hareketler yüklenemedi: $e'),
          data: (items) => items.isEmpty
              ? const Text('Kayıt yok.')
              : Column(
                  children: items
                      .map(
                        (t) => Card(
                          child: ListTile(
                            title: Text(formatUsd(t.amount)),
                            subtitle: Text('${t.transactionType}\n${dateFmt.format(t.date.toLocal())}'),
                            isThreeLine: true,
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 24),
        Text('Kazanılan primler', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        primsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Primler yüklenemedi: $e'),
          data: (items) {
            if (items == null || items.isEmpty) return const Text('Prim kaydı yok.');
            return Column(
              children: items
                  .map(
                    (p) => Card(
                      child: ListTile(
                        title: Text(p.transferNumber),
                        subtitle: Text(dateFmt.format(p.earnedAt.toLocal())),
                        trailing: Text(formatUsd(p.primAmount)),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
