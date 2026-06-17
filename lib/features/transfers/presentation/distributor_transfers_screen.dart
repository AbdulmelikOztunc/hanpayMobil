import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/i18n/app_locale.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/features/transfers/data/transfer_repository.dart';
import 'package:hanpay_mobil/shared/models/transfer.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/transfer_status_chip.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

final distributorActiveProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(transferRepositoryProvider).getDistributorTransfers(DistributorTab.active);
});

final distributorHistoryProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(transferRepositoryProvider).getDistributorTransfers(DistributorTab.history);
});

class DistributorTransfersScreen extends ConsumerStatefulWidget {
  const DistributorTransfersScreen({super.key});

  @override
  ConsumerState<DistributorTransfersScreen> createState() => _DistributorTransfersScreenState();
}

class _DistributorTransfersScreenState extends ConsumerState<DistributorTransfersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Geçmiş'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _DistributorList(active: true),
              _DistributorList(active: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _DistributorList extends ConsumerWidget {
  const _DistributorList({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = active ? distributorActiveProvider : distributorHistoryProvider;
    final async = ref.watch(provider);
    final locale = ref.watch(localeControllerProvider);
    final money = NumberFormat.currency(
        locale: locale.numberFormatTag, symbol: r'$', decimalDigits: 2);
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm', locale.numberFormatTag);

    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(provider),
      ),
      data: (transfers) {
        if (transfers.isEmpty) {
          return Center(child: Text(active ? 'Aktif havale yok.' : 'Geçmiş havale yok.'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: transfers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final tx = transfers[i];
              return _DistributorCard(
                transfer: tx,
                moneyFmt: money,
                dateFmt: dateFmt,
                active: active,
                onChanged: () {
                  ref.invalidate(distributorActiveProvider);
                  ref.invalidate(distributorHistoryProvider);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _DistributorCard extends ConsumerStatefulWidget {
  const _DistributorCard({
    required this.transfer,
    required this.moneyFmt,
    required this.dateFmt,
    required this.active,
    required this.onChanged,
  });

  final TransferDto transfer;
  final NumberFormat moneyFmt;
  final DateFormat dateFmt;
  final bool active;
  final VoidCallback onChanged;

  @override
  ConsumerState<_DistributorCard> createState() => _DistributorCardState();
}

class _DistributorCardState extends ConsumerState<_DistributorCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      widget.onChanged();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _claim() async {
    await _run(() => ref.read(transferRepositoryProvider).claim(widget.transfer.id));
  }

  Future<void> _complete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Havaleyi tamamla'),
        content: const Text('Bu havaleyi ödenmiş olarak işaretlemek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tamamla')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() => ref.read(transferRepositoryProvider).complete(widget.transfer.id));
  }

  Future<void> _reject() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Havaleyi reddet'),
        content: const Text('Bu havaleyi reddetmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() => ref.read(transferRepositoryProvider).reject(widget.transfer.id));
  }

  Future<void> _uploadReceipt() async {
    final choice = await showModalBottomSheet<_UploadSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, _UploadSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, _UploadSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.file_present_outlined),
              title: const Text('Dosya seç (PDF/JPG/PNG/WebP)'),
              onTap: () => Navigator.pop(ctx, _UploadSource.file),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    String? path;
    if (choice == _UploadSource.file) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
      path = result?.files.single.path;
    } else {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: choice == _UploadSource.camera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
      );
      path = image?.path;
    }
    if (path == null) return;
    await _run(
      () => ref.read(transferRepositoryProvider).uploadReceipt(widget.transfer.id, filePath: path!),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dekont yüklendi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transfer;
    final status = tx.status;
    final showClaim = widget.active && status == TransferStatus.pending && tx.distributorId == null;
    final showUpload = widget.active &&
        (status == TransferStatus.inProgress || status == TransferStatus.receiptUploaded);
    final showComplete = widget.active && status == TransferStatus.receiptUploaded;
    final showReject =
        widget.active && (status == TransferStatus.inProgress || status == TransferStatus.receiptUploaded);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/distributor/transfers/${tx.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${tx.transferNumber}', style: Theme.of(context).textTheme.titleMedium),
                  TransferStatusChip(status: status),
                ],
              ),
              const SizedBox(height: 6),
              Text('${tx.senderFullName} → ${tx.receiverFullName}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('Telefon: ${tx.receiverPhone}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tx.state, style: Theme.of(context).textTheme.bodySmall),
                  Text(widget.moneyFmt.format(tx.amount),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(widget.dateFmt.format(tx.createdAt.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall),
              if (showClaim || showUpload || showComplete || showReject) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (showClaim)
                      FilledButton.icon(
                        onPressed: _busy ? null : _claim,
                        icon: const Icon(Icons.gavel),
                        label: const Text('Üstlen'),
                      ),
                    if (showUpload)
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _uploadReceipt,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Dekont yükle'),
                      ),
                    if (showComplete)
                      FilledButton.icon(
                        onPressed: _busy ? null : _complete,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Tamamla'),
                      ),
                    if (showReject)
                      TextButton.icon(
                        onPressed: _busy ? null : _reject,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Reddet'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _UploadSource { camera, gallery, file }
