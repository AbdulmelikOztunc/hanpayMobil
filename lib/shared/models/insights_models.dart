import 'package:hanpay_mobil/shared/models/json_helpers.dart';

class PaymentTypeTotals {
  const PaymentTypeTotals({required this.cash, required this.bank, required this.total});

  final double cash;
  final double bank;
  final double total;
}

class PaymentTypeRatios {
  const PaymentTypeRatios({required this.cashRatio, required this.bankRatio});

  final double cashRatio;
  final double bankRatio;
}

class PaymentDistributionDto {
  const PaymentDistributionDto({
    required this.periodYear,
    required this.periodMonth,
    required this.totalTransferCount,
    required this.totalTransferAmount,
    required this.usdTotals,
    required this.tlTotals,
    required this.usdRatios,
    required this.tlRatios,
  });

  final int periodYear;
  final int periodMonth;
  final int totalTransferCount;
  final double totalTransferAmount;
  final PaymentTypeTotals usdTotals;
  final PaymentTypeTotals tlTotals;
  final PaymentTypeRatios usdRatios;
  final PaymentTypeRatios tlRatios;

  factory PaymentDistributionDto.fromJson(Map<String, dynamic> json) {
    final totals = _map(json['totals'] ?? json['Totals']);
    final ratios = _map(json['ratios'] ?? json['Ratios']);
    final usdTotals = _map(totals['usd'] ?? totals['USD'] ?? totals['Usd']);
    final tlTotals = _map(totals['tl'] ?? totals['TL'] ?? totals['Tl']);
    final usdRatios = _map(ratios['usd'] ?? ratios['USD'] ?? ratios['Usd']);
    final tlRatios = _map(ratios['tl'] ?? ratios['TL'] ?? ratios['Tl']);

    final usdCash = jsonDouble(usdTotals['cash'] ?? usdTotals['Cash']);
    final usdBank = jsonDouble(usdTotals['bank'] ?? usdTotals['Bank']);
    final tlCash = jsonDouble(tlTotals['cash'] ?? tlTotals['Cash']);
    final tlBank = jsonDouble(tlTotals['bank'] ?? tlTotals['Bank']);

    return PaymentDistributionDto(
      periodYear: jsonInt(json['periodYear'] ?? json['PeriodYear']),
      periodMonth: jsonInt(json['periodMonth'] ?? json['PeriodMonth']),
      totalTransferCount: jsonInt(
        json['totalTransferCount'] ??
            json['TotalTransferCount'] ??
            json['paidTransferCount'] ??
            json['PaidTransferCount'],
      ),
      totalTransferAmount: jsonDouble(json['totalTransferAmount'] ?? json['TotalTransferAmount']),
      usdTotals: PaymentTypeTotals(
        cash: usdCash,
        bank: usdBank,
        total: jsonDouble(usdTotals['total'] ?? usdTotals['Total']).clamp(0, double.infinity) == 0
            ? usdCash + usdBank
            : jsonDouble(usdTotals['total'] ?? usdTotals['Total']),
      ),
      tlTotals: PaymentTypeTotals(
        cash: tlCash,
        bank: tlBank,
        total: jsonDouble(tlTotals['total'] ?? tlTotals['Total']).clamp(0, double.infinity) == 0
            ? tlCash + tlBank
            : jsonDouble(tlTotals['total'] ?? tlTotals['Total']),
      ),
      usdRatios: PaymentTypeRatios(
        cashRatio: jsonDouble(usdRatios['cashRatio'] ?? usdRatios['CashRatio']),
        bankRatio: jsonDouble(usdRatios['bankRatio'] ?? usdRatios['BankRatio']),
      ),
      tlRatios: PaymentTypeRatios(
        cashRatio: jsonDouble(tlRatios['cashRatio'] ?? tlRatios['CashRatio']),
        bankRatio: jsonDouble(tlRatios['bankRatio'] ?? tlRatios['BankRatio']),
      ),
    );
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}

class MonthlyVolumePoint {
  const MonthlyVolumePoint({
    required this.year,
    required this.month,
    required this.amount,
    required this.transferCount,
  });

  final int year;
  final int month;
  final double amount;
  final int transferCount;

  factory MonthlyVolumePoint.fromJson(Map<String, dynamic> json, {int fallbackYear = 0}) {
    final year = jsonInt(json['year'] ?? json['Year']);
    return MonthlyVolumePoint(
      year: year > 0 ? year : fallbackYear,
      month: jsonInt(json['month'] ?? json['Month']),
      amount: jsonDouble(
        json['amount'] ?? json['Amount'] ?? json['totalAmount'] ?? json['TotalAmount'],
      ),
      transferCount: jsonInt(
        json['transferCount'] ?? json['TransferCount'] ?? json['count'] ?? json['Count'],
      ),
    );
  }
}

class MonthlyTransferVolumeDto {
  const MonthlyTransferVolumeDto({
    required this.totalAmount,
    required this.totalTransferCount,
    required this.points,
  });

  final double totalAmount;
  final int totalTransferCount;
  final List<MonthlyVolumePoint> points;

  factory MonthlyTransferVolumeDto.fromJson(Object? raw) {
    final json = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final fallbackYear = jsonInt(json['year'] ?? json['Year']);
    final pointsRaw = json['points'] ??
        json['Points'] ??
        json['monthly'] ??
        json['Monthly'] ??
        json['series'] ??
        json['Series'];
    final points = (pointsRaw is List ? pointsRaw : const [])
        .whereType<Map>()
        .map((e) => MonthlyVolumePoint.fromJson(Map<String, dynamic>.from(e), fallbackYear: fallbackYear))
        .where((p) => p.month > 0 && p.year > 0)
        .toList()
      ..sort((a, b) => a.year != b.year ? a.year.compareTo(b.year) : a.month.compareTo(b.month));

    final amountSum = points.fold<double>(0, (s, p) => s + p.amount);
    final countSum = points.fold<int>(0, (s, p) => s + p.transferCount);

    return MonthlyTransferVolumeDto(
      totalAmount: jsonDouble(
            json['totalAmount'] ?? json['TotalAmount'] ?? json['totalAmountUsd'] ?? json['TotalAmountUsd'],
          ) ==
              0
          ? amountSum
          : jsonDouble(
              json['totalAmount'] ?? json['TotalAmount'] ?? json['totalAmountUsd'] ?? json['TotalAmountUsd'],
            ),
      totalTransferCount: jsonInt(
                json['totalTransferCount'] ??
                    json['TotalTransferCount'] ??
                    json['totalCount'] ??
                    json['TotalCount'],
              ) ==
              0
          ? countSum
          : jsonInt(
              json['totalTransferCount'] ??
                  json['TotalTransferCount'] ??
                  json['totalCount'] ??
                  json['TotalCount'],
            ),
      points: points,
    );
  }
}

class TransferReportRow {
  const TransferReportRow({
    required this.createdAtLocal,
    required this.status,
    required this.receiverFullName,
    required this.amount,
    required this.netCommission,
    required this.totalUsd,
    this.transferNumber,
    this.receiverPhone = '',
    this.totalTl = 0,
  });

  final DateTime createdAtLocal;
  final String? transferNumber;
  final String status;
  final String receiverFullName;
  final String receiverPhone;
  final double amount;
  final double netCommission;
  final double totalUsd;
  final double totalTl;

  factory TransferReportRow.fromJson(Map<String, dynamic> json) => TransferReportRow(
        createdAtLocal: jsonDate(json['createdAtLocal'] ?? json['CreatedAtLocal'] ?? json['createdAt']),
        transferNumber: json['transferNumber'] as String? ?? json['TransferNumber'] as String?,
        status: jsonStr(json['status'] ?? json['Status']),
        receiverFullName: jsonStr(json['receiverFullName'] ?? json['ReceiverFullName']),
        receiverPhone: jsonStr(json['receiverPhone'] ?? json['ReceiverPhone']),
        amount: jsonDouble(json['amount'] ?? json['Amount']),
        netCommission: jsonDouble(json['netCommission'] ?? json['NetCommission']),
        totalUsd: jsonDouble(json['totalUsd'] ?? json['TotalUsd']),
        totalTl: jsonDouble(json['totalTl'] ?? json['TotalTl']),
      );
}

class TransferReportExport {
  const TransferReportExport({required this.bytes, required this.filename});

  final List<int> bytes;
  final String filename;
}
