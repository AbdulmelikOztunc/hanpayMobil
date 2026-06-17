import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/features/dashboard/data/dashboard_repository.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/stat_card.dart';

final agentDashboardProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(dashboardRepositoryProvider).getAgentDashboard();
});

class AgentDashboardScreen extends ConsumerWidget {
  const AgentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(agentDashboardProvider);

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
            if (data.usdTryExchangeRate != null) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: const Text('USD/TRY kuru'),
                  trailing: Text(data.usdTryExchangeRate!.toStringAsFixed(4)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
