import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/features/agent/data/agent_repository.dart';
import 'package:hanpay_mobil/features/dashboard/data/dashboard_repository.dart';
import 'package:hanpay_mobil/features/transfers/data/transfer_repository.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/stat_card.dart';
import 'package:hanpay_mobil/shared/widgets/transfer_status_chip.dart';
import 'package:intl/intl.dart';

final agentDashboardProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(dashboardRepositoryProvider).getAgentDashboard();
});

final agentDashboardTransfersProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(transferRepositoryProvider).getMyAgentTransfers();
});

class AgentDashboardScreen extends ConsumerWidget {
  const AgentDashboardScreen({super.key});

  Future<void> _editExchangeRate(BuildContext context, WidgetRef ref, double? current) async {
    final ctrl = TextEditingController(text: current?.toStringAsFixed(4) ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('USD/TRY kuru'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Kur'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
        ],
      ),
    );
    final value = double.tryParse(ctrl.text.replaceAll(',', '.'));
    ctrl.dispose();
    if (ok != true || value == null || value <= 0) return;
    try {
      await ref.read(agentRepositoryProvider).updateOwnExchangeRate(value);
      ref.invalidate(agentDashboardProvider);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(agentDashboardProvider);
    final transfersAsync = ref.watch(agentDashboardTransfersProvider);
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');

    return async.when(
      loading: () => const LoadingView(message: 'Dashboard yükleniyor...'),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(agentDashboardProvider),
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(agentDashboardProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Agent Dashboard', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  label: 'Günlük transfer',
                  value: formatUsd(data.dailyTotalTransfers),
                  icon: Icons.today_outlined,
                ),
                StatCard(
                  label: 'Aylık transfer',
                  value: formatUsd(data.monthlyTotalTransfers),
                  icon: Icons.calendar_month_outlined,
                ),
                StatCard(
                  label: 'Bakiye',
                  value: formatUsd(data.accountBalance),
                  icon: Icons.account_balance_wallet_outlined,
                ),
                StatCard(
                  label: 'Komisyon oranı',
                  value: formatPercentFraction(data.commissionRate),
                  icon: Icons.percent,
                ),
                StatCard(
                  label: 'Toplam kâr',
                  value: formatUsd(data.totalProfit),
                  icon: Icons.trending_up,
                ),
                StatCard(
                  label: 'Transfer adedi',
                  value: '${data.totalTransferCount}',
                  icon: Icons.swap_horiz,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.currency_exchange),
                title: const Text('USD/TRY kuru'),
                subtitle: const Text('Acente kuru güncelle'),
                trailing: Text(data.usdTryExchangeRate?.toStringAsFixed(4) ?? '-'),
                onTap: () => _editExchangeRate(context, ref, data.usdTryExchangeRate),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Son havaleler', style: Theme.of(context).textTheme.titleMedium),
                TextButton(onPressed: () => context.go('/agent/transfers'), child: const Text('Tümü')),
              ],
            ),
            transfersAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (transfers) {
                final recent = [...transfers]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                final top = recent.take(5).toList();
                if (top.isEmpty) return const Text('Henüz havale yok.');
                return Column(
                  children: top
                      .map(
                        (tx) => Card(
                          child: ListTile(
                            title: Text('#${tx.transferNumber}'),
                            subtitle: Text('${tx.receiverFullName}\n${dateFmt.format(tx.createdAt.toLocal())}'),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatUsd(tx.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                                TransferStatusChip(status: tx.status),
                              ],
                            ),
                            onTap: () => context.push('/agent/transfers/${tx.id}'),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
