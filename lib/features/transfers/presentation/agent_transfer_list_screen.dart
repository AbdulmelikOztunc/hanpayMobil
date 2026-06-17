import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/i18n/app_locale.dart';
import 'package:hanpay_mobil/features/transfers/data/transfer_repository.dart';
import 'package:hanpay_mobil/shared/models/transfer.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/transfer_status_chip.dart';
import 'package:intl/intl.dart';

final agentTransfersProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(transferRepositoryProvider).getMyAgentTransfers();
});

class AgentTransferListScreen extends ConsumerWidget {
  const AgentTransferListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(agentTransfersProvider);
    final locale = ref.watch(localeControllerProvider);
    final money = NumberFormat.currency(
      locale: locale.numberFormatTag,
      symbol: r'$',
      decimalDigits: 2,
    );
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm', locale.numberFormatTag);

    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(agentTransfersProvider),
      ),
      data: (transfers) {
        if (transfers.isEmpty) {
          return const Center(child: Text('Henüz havale yok.'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(agentTransfersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: transfers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = transfers[index];
              return _TransferTile(
                transfer: tx,
                moneyFmt: money,
                dateFmt: dateFmt,
                onTap: () => context.push('/agent/transfers/${tx.id}'),
              );
            },
          ),
        );
      },
    );
  }
}

class _TransferTile extends StatelessWidget {
  const _TransferTile({
    required this.transfer,
    required this.moneyFmt,
    required this.dateFmt,
    required this.onTap,
  });

  final TransferDto transfer;
  final NumberFormat moneyFmt;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${transfer.transferNumber}',
                      style: Theme.of(context).textTheme.titleMedium),
                  TransferStatusChip(status: transfer.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${transfer.senderFullName} → ${transfer.receiverFullName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(transfer.state,
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    moneyFmt.format(transfer.amount),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                dateFmt.format(transfer.createdAt.toLocal()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
