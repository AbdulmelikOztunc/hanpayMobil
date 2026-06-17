import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/features/dashboard/data/dashboard_repository.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/stat_card.dart';

final adminDashboardProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(dashboardRepositoryProvider).getAdminDashboard();
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminDashboardProvider);

    return async.when(
      loading: () => const LoadingView(message: 'Dashboard yükleniyor...'),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(adminDashboardProvider),
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminDashboardProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Admin Dashboard', style: Theme.of(context).textTheme.headlineSmall),
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
                  label: 'Agent bakiyesi',
                  value: formatUsd(data.totalAgentBalance),
                  icon: Icons.storefront_outlined,
                ),
                StatCard(
                  label: 'Distributor bakiyesi',
                  value: formatUsd(data.totalDistributorBalance),
                  icon: Icons.local_shipping_outlined,
                ),
                StatCard(
                  label: 'Transfer hacmi',
                  value: formatUsd(data.totalTransfers),
                  icon: Icons.swap_horiz,
                ),
                StatCard(
                  label: 'Transfer adedi',
                  value: '${data.totalTransferCount}',
                  icon: Icons.numbers,
                ),
                StatCard(
                  label: 'Toplam komisyon',
                  value: formatUsd(data.totalCommission),
                  icon: Icons.pie_chart_outline,
                ),
                if (data.totalSystemBalance != null)
                  StatCard(
                    label: 'Sistem bakiyesi',
                    value: formatUsd(data.totalSystemBalance!),
                    icon: Icons.account_balance_outlined,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
