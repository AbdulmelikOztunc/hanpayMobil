import 'package:hanpay_mobil/shared/models/json_helpers.dart';

class AgentBalanceSummary {
  const AgentBalanceSummary({
    required this.currentBalance,
    required this.creditLimit,
    required this.currency,
    required this.openingBalance,
    required this.deposits,
    required this.transfers,
  });

  final double currentBalance;
  final double creditLimit;
  final String currency;
  final double openingBalance;
  final List<BalanceDepositItem> deposits;
  final List<BalanceTransferItem> transfers;

  factory AgentBalanceSummary.fromJson(Map<String, dynamic> json) => AgentBalanceSummary(
        currentBalance: jsonDouble(json['currentBalance']),
        creditLimit: jsonDouble(json['creditLimit']),
        currency: jsonStr(json['currency']).isEmpty ? 'USD' : jsonStr(json['currency']),
        openingBalance: jsonDouble(json['openingBalance']),
        deposits: (json['deposits'] as List<dynamic>? ?? [])
            .map((e) => BalanceDepositItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        transfers: (json['transfers'] as List<dynamic>? ?? [])
            .map((e) => BalanceTransferItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DistributorBalanceSummary {
  const DistributorBalanceSummary({
    required this.currentBalance,
    required this.currency,
    required this.openingBalance,
    required this.deposits,
    required this.transfers,
  });

  final double currentBalance;
  final String currency;
  final double openingBalance;
  final List<BalanceDepositItem> deposits;
  final List<BalanceTransferItem> transfers;

  factory DistributorBalanceSummary.fromJson(Map<String, dynamic> json) =>
      DistributorBalanceSummary(
        currentBalance: jsonDouble(json['currentBalance']),
        currency: jsonStr(json['currency']).isEmpty ? 'USD' : jsonStr(json['currency']),
        openingBalance: jsonDouble(json['openingBalance']),
        deposits: (json['deposits'] as List<dynamic>? ?? [])
            .map((e) => BalanceDepositItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        transfers: (json['transfers'] as List<dynamic>? ?? [])
            .map((e) => BalanceTransferItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class BalanceDepositItem {
  const BalanceDepositItem({
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
    required this.performedByName,
  });

  final int id;
  final DateTime date;
  final double amount;
  final String description;
  final String performedByName;

  factory BalanceDepositItem.fromJson(Map<String, dynamic> json) => BalanceDepositItem(
        id: jsonInt(json['id']),
        date: jsonDate(json['date']),
        amount: jsonDouble(json['amount']),
        description: jsonStr(json['description']),
        performedByName: jsonStr(json['performedByName']),
      );
}

class BalanceTransferItem {
  const BalanceTransferItem({
    required this.transferId,
    required this.transferNumber,
    required this.amount,
    required this.totalAmount,
    required this.date,
    this.counterpartyName,
    this.status,
  });

  final int transferId;
  final String transferNumber;
  final double amount;
  final double totalAmount;
  final DateTime date;
  final String? counterpartyName;
  final String? status;

  factory BalanceTransferItem.fromJson(Map<String, dynamic> json) => BalanceTransferItem(
        transferId: jsonInt(json['transferId']),
        transferNumber: jsonStr(json['transferNumber']),
        amount: jsonDouble(json['amount']),
        totalAmount: jsonDouble(json['totalAmount'] ?? json['amount']),
        date: jsonDate(json['date']),
        counterpartyName: json['distributorName'] as String? ?? json['agentName'] as String?,
        status: json['status']?.toString(),
      );
}

class DistributorPrimRow {
  const DistributorPrimRow({
    required this.id,
    required this.transferNumber,
    required this.earnedAt,
    required this.transferAmount,
    required this.primAmount,
    this.isReversed = false,
    this.distributorName,
  });

  final int id;
  final String transferNumber;
  final DateTime earnedAt;
  final double transferAmount;
  final double primAmount;
  final bool isReversed;
  final String? distributorName;

  factory DistributorPrimRow.fromJson(Map<String, dynamic> json) => DistributorPrimRow(
        id: jsonInt(json['id']),
        transferNumber: jsonStr(json['transferNumber']),
        earnedAt: jsonDate(json['earnedAt']),
        transferAmount: jsonDouble(json['transferAmount']),
        primAmount: jsonDouble(json['primAmount']),
        isReversed: json['isReversed'] == true,
        distributorName: json['distributorName'] as String?,
      );
}

class TransferSummaryQuote {
  const TransferSummaryQuote({
    required this.transferAmountUsd,
    required this.exchangeRate,
    required this.commission,
    required this.netCommissionUsd,
    required this.totalUsd,
    required this.totalTl,
    required this.remainingUsd,
    required this.remainingTl,
    this.transferAmountUsdWords = '',
  });

  final double transferAmountUsd;
  final double exchangeRate;
  final double commission;
  final double netCommissionUsd;
  final double totalUsd;
  final double totalTl;
  final double remainingUsd;
  final double remainingTl;
  final String transferAmountUsdWords;

  factory TransferSummaryQuote.fromJson(Map<String, dynamic> json) => TransferSummaryQuote(
        transferAmountUsd: jsonDouble(json['transferAmountUsd']),
        exchangeRate: jsonDouble(json['exchangeRate']),
        commission: jsonDouble(json['commission']),
        netCommissionUsd: jsonDouble(json['netCommissionUsd']),
        totalUsd: jsonDouble(json['totalUsd']),
        totalTl: jsonDouble(json['total'] ?? json['totalAmountTl']),
        remainingUsd: jsonDouble(json['remainingUsd']),
        remainingTl: jsonDouble(json['remainingTl']),
        transferAmountUsdWords: jsonStr(json['transferAmountUsdWords']),
      );
}
