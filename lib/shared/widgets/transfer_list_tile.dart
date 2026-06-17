import 'package:flutter/material.dart';
import 'package:hanpay_mobil/shared/models/transfer.dart';
import 'package:hanpay_mobil/shared/widgets/transfer_status_chip.dart';
import 'package:intl/intl.dart';

class TransferListTile extends StatelessWidget {
  const TransferListTile({
    super.key,
    required this.transfer,
    required this.moneyFmt,
    required this.dateFmt,
    required this.onTap,
    this.subtitle,
  });

  final TransferDto transfer;
  final NumberFormat moneyFmt;
  final DateFormat dateFmt;
  final VoidCallback onTap;
  final String? subtitle;

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
                subtitle ??
                    '${transfer.senderFullName} → ${transfer.receiverFullName}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(transfer.state, style: Theme.of(context).textTheme.bodySmall),
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
