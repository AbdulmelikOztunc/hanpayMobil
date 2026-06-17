import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/features/agent/data/agent_repository.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/balance_ledger_body.dart';

final agentBalanceProvider = FutureProvider.autoDispose((ref) {
  final now = DateTime.now();
  return ref.watch(agentRepositoryProvider).getBalance(year: now.year, month: now.month);
});

class AgentBalanceScreen extends ConsumerWidget {
  const AgentBalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(agentBalanceProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(agentBalanceProvider)),
      data: (data) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(agentBalanceProvider),
        child: BalanceLedgerScreenBody(
          currentBalance: data.currentBalance,
          openingBalance: data.openingBalance,
          currency: data.currency,
          creditLimit: data.creditLimit,
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
