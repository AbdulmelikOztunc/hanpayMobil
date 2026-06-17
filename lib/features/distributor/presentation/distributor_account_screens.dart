import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/features/distributor/data/distributor_repository.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/balance_ledger_body.dart';
import 'package:hanpay_mobil/shared/widgets/stat_card.dart';

final distributorBalanceProvider = FutureProvider.autoDispose((ref) {
  final now = DateTime.now();
  return ref.watch(distributorRepositoryProvider).getBalance(year: now.year, month: now.month);
});

class DistributorBalanceScreen extends ConsumerWidget {
  const DistributorBalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(distributorBalanceProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) =>
          ErrorView(message: e.toString(), onRetry: () => ref.invalidate(distributorBalanceProvider)),
      data: (data) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(distributorBalanceProvider),
        child: BalanceLedgerScreenBody(
          currentBalance: data.currentBalance,
          openingBalance: data.openingBalance,
          currency: data.currency,
          deposits: data.deposits
              .map((d) => BalanceLedgerDeposit(
                    date: d.date,
                    amount: d.amount,
                    description: d.description,
                    performedByName: d.performedByName,
                  ))
              .toList(),
          transfers: data.transfers
              .map((t) => BalanceLedgerTransfer(
                    transferNumber: t.transferNumber,
                    totalAmount: t.totalAmount,
                    date: t.date,
                    counterpartyName: t.counterpartyName,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

final distributorPrimsProvider = FutureProvider.autoDispose((ref) {
  final now = DateTime.now();
  return ref.watch(distributorRepositoryProvider).getMyPrims(year: now.year, month: now.month);
});

class DistributorPrimsScreen extends ConsumerWidget {
  const DistributorPrimsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(distributorPrimsProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) =>
          ErrorView(message: e.toString(), onRetry: () => ref.invalidate(distributorPrimsProvider)),
      data: (rows) {
        final earned = rows.where((r) => !r.isReversed).fold<double>(0, (s, r) => s + r.primAmount);
        final reversed = rows.where((r) => r.isReversed).fold<double>(0, (s, r) => s + r.primAmount);
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(distributorPrimsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  StatCard(label: 'Kazanılan', value: formatUsd(earned), icon: Icons.trending_up),
                  StatCard(label: 'Geri alınan', value: formatUsd(reversed), icon: Icons.undo),
                  StatCard(label: 'Net', value: formatUsd(earned - reversed), icon: Icons.savings),
                  StatCard(label: 'Kayıt', value: '${rows.length}', icon: Icons.list_alt),
                ],
              ),
              const SizedBox(height: 16),
              if (rows.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Prim kaydı yok.')))
              else
                ...rows.map(
                  (r) => Card(
                    child: ListTile(
                      title: Text('#${r.transferNumber}'),
                      subtitle: Text(
                        '${r.earnedAt.day}.${r.earnedAt.month}.${r.earnedAt.year} · Havale ${formatUsd(r.transferAmount)}',
                      ),
                      trailing: Text(
                        formatUsd(r.primAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: r.isReversed ? Colors.red : Colors.green.shade700,
                          decoration: r.isReversed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

final distributorUsersProvider = FutureProvider.autoDispose((ref) async {
  final users = await ref.watch(distributorRepositoryProvider).getUsers();
  return users
      .where((u) => u.role.contains('Distributor'))
      .toList(growable: false);
});

class DistributorUsersScreen extends ConsumerWidget {
  const DistributorUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(distributorUsersProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) =>
          ErrorView(message: e.toString(), onRetry: () => ref.invalidate(distributorUsersProvider)),
      data: (users) {
        if (users.isEmpty) return const Center(child: Text('Kullanıcı bulunamadı.'));
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(distributorUsersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final u = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(u.fullName.isNotEmpty ? u.fullName[0] : '?')),
                  title: Text(u.fullName),
                  subtitle: Text('${u.email}\n${u.role}'),
                  isThreeLine: true,
                  trailing: Icon(
                    u.isActive ? Icons.check_circle_outline : Icons.block,
                    color: u.isActive ? Colors.green : Colors.grey,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
