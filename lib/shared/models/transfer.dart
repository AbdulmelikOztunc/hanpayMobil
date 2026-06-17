enum TransferStatus {
  pending,
  inProgress,
  receiptUploaded,
  paid,
  cancelled,
  onHold,
  frozen,
  stateChanged,
  cancellationRequested,
  unknown;

  String get apiValue => switch (this) {
        TransferStatus.pending => 'Pending',
        TransferStatus.inProgress => 'InProgress',
        TransferStatus.receiptUploaded => 'ReceiptUploaded',
        TransferStatus.paid => 'Paid',
        TransferStatus.cancelled => 'Cancelled',
        TransferStatus.onHold => 'OnHold',
        TransferStatus.frozen => 'Frozen',
        TransferStatus.stateChanged => 'StateChanged',
        TransferStatus.cancellationRequested => 'CancellationRequested',
        TransferStatus.unknown => 'Unknown',
      };

  /// Locale key suffix — e.g. `transfer_status_pending`.
  String get localeKey => 'transfer_status_${apiValue[0].toLowerCase()}${apiValue.substring(1)}';
}

TransferStatus parseTransferStatus(Object? raw) {
  if (raw == null) return TransferStatus.unknown;
  if (raw is int) {
    if (raw >= 0 && raw < TransferStatus.values.length) return TransferStatus.values[raw];
    return TransferStatus.unknown;
  }
  final value = raw.toString();
  for (final s in TransferStatus.values) {
    if (s.apiValue == value) return s;
  }
  return TransferStatus.unknown;
}

class TransferDto {
  const TransferDto({
    required this.id,
    required this.transferNumber,
    required this.senderFullName,
    required this.receiverFullName,
    required this.receiverPhone,
    required this.state,
    required this.stateId,
    required this.amount,
    required this.collectionCurrency,
    required this.exchangeRate,
    required this.commission,
    required this.netCommissionUsd,
    required this.totalAmount,
    required this.totalAmountTl,
    required this.cashUsdAmount,
    required this.cashTlAmount,
    required this.bankUsdAmount,
    required this.bankTlAmount,
    required this.status,
    required this.createdAt,
    required this.agentId,
    required this.agentName,
    required this.distributorName,
    this.senderName = '',
    this.senderSurname = '',
    this.receiverName = '',
    this.receiverSurname = '',
    this.receiverAddress = '',
    this.amountInWords = '',
    this.commissionDiscountUsd = 0,
    this.distributorId,
    this.distributorReceiptFilePath,
    this.pendingCancellationReason,
  });

  final int id;
  final String transferNumber;
  final String senderName;
  final String senderSurname;
  final String senderFullName;
  final String receiverName;
  final String receiverSurname;
  final String receiverFullName;
  final String receiverPhone;
  final String receiverAddress;
  final int stateId;
  final String state;
  final double amount;
  final String amountInWords;
  final String collectionCurrency;
  final double exchangeRate;
  final double commission;
  final double commissionDiscountUsd;
  final double netCommissionUsd;
  final double totalAmount;
  final double totalAmountTl;
  final double cashUsdAmount;
  final double cashTlAmount;
  final double bankUsdAmount;
  final double bankTlAmount;
  final TransferStatus status;
  final DateTime createdAt;
  final int agentId;
  final String agentName;
  final int? distributorId;
  final String distributorName;
  final String? distributorReceiptFilePath;
  final String? pendingCancellationReason;

  factory TransferDto.fromJson(Map<String, dynamic> json) {
    double d(Object? v) => (v as num?)?.toDouble() ?? 0;
    String s(Object? v) => v?.toString() ?? '';

    DateTime parseDate(Object? raw) {
      if (raw == null) return DateTime.now();
      if (raw is DateTime) return raw;
      return DateTime.tryParse(raw.toString())?.toUtc() ?? DateTime.now();
    }

    return TransferDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      transferNumber: s(json['transferNumber']),
      senderName: s(json['senderName']),
      senderSurname: s(json['senderSurname']),
      senderFullName: s(json['senderFullName']),
      receiverName: s(json['receiverName']),
      receiverSurname: s(json['receiverSurname']),
      receiverFullName: s(json['receiverFullName']),
      receiverPhone: s(json['receiverPhone']),
      receiverAddress: s(json['receiverAddress']),
      stateId: (json['stateId'] as num?)?.toInt() ?? 0,
      state: s(json['state']),
      amount: d(json['amount']),
      amountInWords: s(json['amountInWords']),
      collectionCurrency: s(json['collectionCurrency']),
      exchangeRate: d(json['exchangeRate']),
      commission: d(json['commission']),
      commissionDiscountUsd: d(json['commissionDiscountUsd']),
      netCommissionUsd: d(json['netCommissionUsd']),
      totalAmount: d(json['totalAmount']),
      totalAmountTl: d(json['totalAmountTl']),
      cashUsdAmount: d(json['cashUsdAmount']),
      cashTlAmount: d(json['cashTlAmount']),
      bankUsdAmount: d(json['bankUsdAmount']),
      bankTlAmount: d(json['bankTlAmount']),
      status: parseTransferStatus(json['status']),
      createdAt: parseDate(json['createdAt']),
      agentId: (json['agentId'] as num?)?.toInt() ?? 0,
      agentName: s(json['agentName']),
      distributorId: (json['distributorId'] as num?)?.toInt(),
      distributorName: s(json['distributorName']),
      distributorReceiptFilePath: json['distributorReceiptFilePath'] as String?,
      pendingCancellationReason: json['pendingCancellationReason'] as String?,
    );
  }
}
