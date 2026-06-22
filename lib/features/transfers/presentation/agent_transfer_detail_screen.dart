import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/env.dart';
import 'package:hanpay_mobil/features/admin/presentation/admin_partner_dialogs.dart';
import 'package:hanpay_mobil/core/i18n/app_locale.dart';
import 'package:hanpay_mobil/core/i18n/translator_ext.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/features/transfers/data/transfer_repository.dart';
import 'package:hanpay_mobil/features/transfers/presentation/transfer_receipt_pdf.dart';
import 'package:hanpay_mobil/shared/models/transfer.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/transfer_status_chip.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

final transferByIdProvider =
    FutureProvider.autoDispose.family<TransferDto, int>((ref, id) {
  return ref.watch(transferRepositoryProvider).getById(id);
});

class AgentTransferDetailScreen extends ConsumerWidget {
  const AgentTransferDetailScreen({super.key, required this.id, this.allowAdminCancel = false});

  final int id;
  final bool allowAdminCancel;

  Future<void> _showReceipt(BuildContext context, WidgetRef ref, TransferDto tx) async {
    final locale = ref.read(localeControllerProvider);
    final t = ref.read(translatorProvider);
    await Printing.layoutPdf(
      name: 'havale-${tx.transferNumber}.pdf',
      onLayout: (_) => buildTransferReceiptPdf(transfer: tx, locale: locale, t: t),
    );
  }

  Future<void> _sharePdf(WidgetRef ref, TransferDto tx) async {
    final locale = ref.read(localeControllerProvider);
    final t = ref.read(translatorProvider);
    final bytes = await buildTransferReceiptPdf(transfer: tx, locale: locale, t: t);
    await Printing.sharePdf(bytes: bytes, filename: 'havale-${tx.transferNumber}.pdf');
  }

  bool _canCancel(TransferStatus status) {
    return status != TransferStatus.paid &&
        status != TransferStatus.cancelled &&
        status != TransferStatus.frozen &&
        status != TransferStatus.cancellationRequested;
  }

  bool _canEdit(TransferStatus status) {
    return status == TransferStatus.pending ||
        status == TransferStatus.onHold ||
        status == TransferStatus.inProgress;
  }

  Future<void> _requestCancellation(BuildContext context, WidgetRef ref, TransferDto tx) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İptal talebi'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Gerekçe'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gönder')),
        ],
      ),
    );
    if (ok != true || reasonCtrl.text.trim().isEmpty) return;
    try {
      await ref.read(transferRepositoryProvider).createCancellationRequest(
            tx.id,
            reason: reasonCtrl.text.trim(),
          );
      ref.invalidate(transferByIdProvider(id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İptal talebi gönderildi')));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transferByIdProvider(id));
    final locale = ref.watch(localeControllerProvider);
    final money = NumberFormat.currency(locale: locale.numberFormatTag, symbol: r'$', decimalDigits: 2);
    final moneyTl = NumberFormat.currency(locale: locale.numberFormatTag, symbol: '₺', decimalDigits: 2);
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm', locale.numberFormatTag);

    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(transferByIdProvider(id)),
      ),
      data: (tx) {
        return Scaffold(
          appBar: AppBar(
            title: Text('#${tx.transferNumber}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Paylaş',
                onPressed: () => _sharePdf(ref, tx),
              ),
              IconButton(
                icon: const Icon(Icons.print),
                tooltip: 'Yazdır',
                onPressed: () => _showReceipt(context, ref, tx),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    money.format(tx.amount),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TransferStatusChip(status: tx.status),
                ],
              ),
              Text(dateFmt.format(tx.createdAt.toLocal())),
              const SizedBox(height: 16),
              _Section(
                title: ref.tw('transfer_field_sender'),
                rows: [
                  _Row(label: 'İsim', value: tx.senderFullName),
                ],
              ),
              _Section(
                title: ref.tw('transfer_field_receiver'),
                rows: [
                  _Row(label: 'İsim', value: tx.receiverFullName),
                  _Row(label: 'Telefon', value: tx.receiverPhone),
                  _Row(label: 'Eyalet', value: tx.state),
                  if (tx.receiverAddress.isNotEmpty)
                    _Row(label: 'Adres', value: tx.receiverAddress),
                ],
              ),
              _Section(
                title: 'Tutar / Komisyon',
                rows: [
                  _Row(label: 'Kur', value: tx.exchangeRate.toStringAsFixed(4)),
                  _Row(label: 'Komisyon', value: money.format(tx.commission)),
                  if (tx.commissionDiscountUsd > 0)
                    _Row(label: 'İndirim', value: money.format(tx.commissionDiscountUsd)),
                  _Row(label: 'Net komisyon', value: money.format(tx.netCommissionUsd)),
                  _Row(label: 'Toplam USD', value: money.format(tx.totalAmount)),
                  _Row(label: 'Toplam TL', value: moneyTl.format(tx.totalAmountTl)),
                ],
              ),
              _Section(
                title: 'Ödeme dağılımı',
                rows: [
                  if (tx.cashUsdAmount > 0)
                    _Row(label: 'Nakit USD', value: money.format(tx.cashUsdAmount)),
                  if (tx.cashTlAmount > 0)
                    _Row(label: 'Nakit TL', value: moneyTl.format(tx.cashTlAmount)),
                  if (tx.bankUsdAmount > 0)
                    _Row(label: 'Banka USD', value: money.format(tx.bankUsdAmount)),
                  if (tx.bankTlAmount > 0)
                    _Row(label: 'Banka TL', value: moneyTl.format(tx.bankTlAmount)),
                ],
              ),
              _Section(
                title: 'Diğer',
                rows: [
                  _Row(label: 'Acente', value: tx.agentName),
                  if (tx.distributorName.isNotEmpty)
                    _Row(label: 'Dağıtıcı', value: tx.distributorName),
                  if (tx.pendingCancellationReason != null)
                    _Row(label: 'İptal talebi', value: tx.pendingCancellationReason!),
                ],
              ),
              if (tx.distributorReceiptFilePath != null &&
                  tx.distributorReceiptFilePath!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _DistributorReceiptSection(path: tx.distributorReceiptFilePath!),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showReceipt(context, ref, tx),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Makbuzu görüntüle / yazdır'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _sharePdf(ref, tx),
                icon: const Icon(Icons.share),
                label: const Text('Makbuzu paylaş'),
              ),
              if (_canEdit(tx.status)) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => context.push('/agent/transfers/${tx.id}/edit'),
                  icon: const Icon(Icons.edit),
                  label: const Text('Düzenle'),
                ),
              ],
              if (_canCancel(tx.status)) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _requestCancellation(context, ref, tx),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('İptal talebi gönder'),
                ),
              ],
              if (allowAdminCancel && canAdminCancelTransfer(tx.status)) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final cancelled = await showAdminCancelTransferDialog(
                      context,
                      ref,
                      transferId: tx.id,
                      netCommissionUsd: tx.netCommissionUsd,
                    );
                    if (cancelled) ref.invalidate(transferByIdProvider(id));
                  },
                  icon: const Icon(Icons.block),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  label: const Text('Admin iptali'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    )),
            const SizedBox(height: 12),
            for (final r in rows) ...[
              r,
              if (r != rows.last)
                Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _DistributorReceiptSection extends StatelessWidget {
  const _DistributorReceiptSection({required this.path});

  final String path;

  bool get _isImage => RegExp(r'\.(jpe?g|png|webp|gif)$', caseSensitive: false).hasMatch(path);

  @override
  Widget build(BuildContext context) {
    final url = Env.assetUrl(path);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dağıtıcı makbuzu', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(url, fit: BoxFit.contain),
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_file),
                title: const Text('Makbuzu görüntüle'),
                subtitle: Text(path),
                onTap: () {},
              ),
          ],
        ),
      ),
    );
  }
}
