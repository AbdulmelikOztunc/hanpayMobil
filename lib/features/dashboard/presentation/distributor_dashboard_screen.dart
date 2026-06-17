import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/features/dashboard/data/dashboard_repository.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/stat_card.dart';

final distributorDashboardProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(dashboardRepositoryProvider).getDistributorDashboard();
});

class DistributorDashboardScreen extends ConsumerWidget {
  const DistributorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(distributorDashboardProvider);

    return async.when(
      loading: () => const LoadingView(message: 'Dashboard yükleniyor...'),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(distributorDashboardProvider),
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(distributorDashboardProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(data.distributorName, style: Theme.of(context).textTheme.headlineSmall),
            Text('${data.state} • Bakiye: ${formatUsd(data.currentBalance)}'),
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
                  label: 'Bekleyen havale',
                  value: '${data.availableTransferCount}',
                  icon: Icons.inbox_outlined,
                ),
                StatCard(
                  label: 'Aktif havale',
                  value: '${data.activeTransferCount}',
                  icon: Icons.pending_actions_outlined,
                ),
                StatCard(
                  label: 'Bugün ödenen',
                  value: '${data.todayCompletedTransferCount}',
                  icon: Icons.check_circle_outline,
                ),
                StatCard(
                  label: 'Bu ay ödenen',
                  value: '${data.monthCompletedTransferCount}',
                  icon: Icons.date_range_outlined,
                ),
                StatCard(
                  label: 'Aktif tutar',
                  value: formatUsd(data.activeTransferTotalAmount),
                  icon: Icons.payments_outlined,
                ),
                StatCard(
                  label: 'Bu ay tutar',
                  value: formatUsd(data.monthCompletedTransferAmount),
                  icon: Icons.attach_money,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
