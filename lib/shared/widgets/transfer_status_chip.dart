import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/i18n/translator_ext.dart';
import 'package:hanpay_mobil/shared/models/transfer.dart';

class TransferStatusChip extends ConsumerWidget {
  const TransferStatusChip({super.key, required this.status});

  final TransferStatus status;

  Color _bg(ColorScheme scheme) => switch (status) {
        TransferStatus.paid => Colors.green.shade100,
        TransferStatus.pending => Colors.amber.shade100,
        TransferStatus.inProgress => Colors.blue.shade100,
        TransferStatus.receiptUploaded => Colors.teal.shade100,
        TransferStatus.cancelled || TransferStatus.cancellationRequested => Colors.red.shade100,
        TransferStatus.onHold || TransferStatus.frozen => Colors.grey.shade300,
        TransferStatus.stateChanged => Colors.purple.shade100,
        TransferStatus.unknown => scheme.surfaceContainerHighest,
      };

  Color _fg() => switch (status) {
        TransferStatus.paid => Colors.green.shade900,
        TransferStatus.pending => Colors.amber.shade900,
        TransferStatus.inProgress => Colors.blue.shade900,
        TransferStatus.receiptUploaded => Colors.teal.shade900,
        TransferStatus.cancelled || TransferStatus.cancellationRequested => Colors.red.shade900,
        TransferStatus.onHold || TransferStatus.frozen => Colors.grey.shade800,
        TransferStatus.stateChanged => Colors.purple.shade900,
        TransferStatus.unknown => Colors.black87,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final label = ref.tw(status.localeKey);
    final display = label == status.localeKey ? status.apiValue : label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg(scheme),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        display,
        style: TextStyle(color: _fg(), fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
