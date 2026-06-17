import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/i18n/app_locale.dart';
import 'package:hanpay_mobil/features/transfers/data/transfer_repository.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/transfer_list_tile.dart';
import 'package:intl/intl.dart';

final distributorHistoryProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(transferRepositoryProvider).getDistributorTransfers(DistributorTab.history);
});

class DistributorHistoryScreen extends ConsumerWidget {
  const DistributorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(distributorHistoryProvider);
    final locale = ref.watch(localeControllerProvider);
    final money = NumberFormat.currency(locale: locale.numberFormatTag, symbol: r'$', decimalDigits: 2);
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm', locale.numberFormatTag);

    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) =>
          ErrorView(message: e.toString(), onRetry: () => ref.invalidate(distributorHistoryProvider)),
      data: (transfers) {
        if (transfers.isEmpty) return const Center(child: Text('Geçmiş transfer yok.'));
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(distributorHistoryProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: transfers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = transfers[index];
              return TransferListTile(
                transfer: tx,
                moneyFmt: money,
                dateFmt: dateFmt,
                onTap: () => context.push('/distributor/transfers/${tx.id}'),
              );
            },
          ),
        );
      },
    );
  }
}
