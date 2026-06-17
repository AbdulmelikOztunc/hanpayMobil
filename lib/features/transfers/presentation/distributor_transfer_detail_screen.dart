import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/i18n/app_locale.dart';
import 'package:hanpay_mobil/features/transfers/presentation/agent_transfer_detail_screen.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/transfer_status_chip.dart';
import 'package:intl/intl.dart';

class DistributorTransferDetailScreen extends ConsumerWidget {
  const DistributorTransferDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transferByIdProvider(id));
    final locale = ref.watch(localeControllerProvider);
    final money = NumberFormat.currency(
        locale: locale.numberFormatTag, symbol: r'$', decimalDigits: 2);
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm', locale.numberFormatTag);

    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(transferByIdProvider(id)),
      ),
      data: (tx) => Scaffold(
        appBar: AppBar(title: Text('#${tx.transferNumber}')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(money.format(tx.amount),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                TransferStatusChip(status: tx.status),
              ],
            ),
            Text(dateFmt.format(tx.createdAt.toLocal())),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(tx.receiverFullName),
                subtitle: Text('Telefon: ${tx.receiverPhone}\nEyalet: ${tx.state}'),
                isThreeLine: true,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.send_outlined),
                title: Text(tx.senderFullName),
                subtitle: Text('Acente: ${tx.agentName}'),
              ),
            ),
            if (tx.distributorReceiptFilePath != null) ...[
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Dekont yüklendi'),
                  subtitle: Text(tx.distributorReceiptFilePath!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
