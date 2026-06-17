class AgentDashboard {
  const AgentDashboard({
    required this.dailyTotalTransfers,
    required this.monthlyTotalTransfers,
    required this.totalProfit,
    required this.totalTransferCount,
    required this.accountBalance,
    required this.commissionRate,
    this.usdTryExchangeRate,
    this.countryCode,
    this.collectionCurrency,
  });

  final double dailyTotalTransfers;
  final double monthlyTotalTransfers;
  final double totalProfit;
  final int totalTransferCount;
  final double accountBalance;
  final double commissionRate;
  final double? usdTryExchangeRate;
  final String? countryCode;
  final String? collectionCurrency;

  factory AgentDashboard.fromJson(Map<String, dynamic> json) {
    double d(Object? v) => (v as num?)?.toDouble() ?? 0;
    return AgentDashboard(
      dailyTotalTransfers: d(json['dailyTotalTransfers']),
      monthlyTotalTransfers: d(json['monthlyTotalTransfers']),
      totalProfit: d(json['totalProfit']),
      totalTransferCount: (json['totalTransferCount'] as num?)?.toInt() ?? 0,
      accountBalance: d(json['accountBalance']),
      commissionRate: d(json['commissionRate']),
      usdTryExchangeRate: (json['usdTryExchangeRate'] as num?)?.toDouble(),
      countryCode: json['countryCode'] as String?,
      collectionCurrency: json['collectionCurrency'] as String?,
    );
  }
}

class DistributorDashboard {
  const DistributorDashboard({
    required this.distributorName,
    required this.state,
    required this.currentBalance,
    required this.currency,
    required this.availableTransferCount,
    required this.activeTransferCount,
    required this.activeTransferTotalAmount,
    required this.todayCompletedTransferCount,
    required this.todayCompletedTransferAmount,
    required this.monthCompletedTransferCount,
    required this.monthCompletedTransferAmount,
    required this.totalCompletedTransferCount,
    required this.totalCompletedTransferAmount,
  });

  final String distributorName;
  final String state;
  final double currentBalance;
  final String currency;
  final int availableTransferCount;
  final int activeTransferCount;
  final double activeTransferTotalAmount;
  final int todayCompletedTransferCount;
  final double todayCompletedTransferAmount;
  final int monthCompletedTransferCount;
  final double monthCompletedTransferAmount;
  final int totalCompletedTransferCount;
  final double totalCompletedTransferAmount;

  factory DistributorDashboard.fromJson(Map<String, dynamic> json) {
    double d(Object? v) => (v as num?)?.toDouble() ?? 0;
    return DistributorDashboard(
      distributorName: json['distributorName'] as String? ?? '',
      state: json['state'] as String? ?? '',
      currentBalance: d(json['currentBalance']),
      currency: json['currency'] as String? ?? 'USD',
      availableTransferCount: (json['availableTransferCount'] as num?)?.toInt() ?? 0,
      activeTransferCount: (json['activeTransferCount'] as num?)?.toInt() ?? 0,
      activeTransferTotalAmount: d(json['activeTransferTotalAmount']),
      todayCompletedTransferCount: (json['todayCompletedTransferCount'] as num?)?.toInt() ?? 0,
      todayCompletedTransferAmount: d(json['todayCompletedTransferAmount']),
      monthCompletedTransferCount: (json['monthCompletedTransferCount'] as num?)?.toInt() ?? 0,
      monthCompletedTransferAmount: d(json['monthCompletedTransferAmount']),
      totalCompletedTransferCount: (json['totalCompletedTransferCount'] as num?)?.toInt() ?? 0,
      totalCompletedTransferAmount: d(json['totalCompletedTransferAmount']),
    );
  }
}

class AdminDashboard {
  const AdminDashboard({
    required this.totalAgentBalance,
    required this.totalDistributorBalance,
    required this.totalTransfers,
    required this.totalCommission,
    required this.totalTransferCount,
    this.totalSystemBalance,
  });

  final double totalAgentBalance;
  final double totalDistributorBalance;
  final double totalTransfers;
  final double totalCommission;
  final int totalTransferCount;
  final double? totalSystemBalance;

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    double d(Object? v) => (v as num?)?.toDouble() ?? 0;
    return AdminDashboard(
      totalAgentBalance: d(json['totalAgentBalance']),
      totalDistributorBalance: d(json['totalDistributorBalance']),
      totalTransfers: d(json['totalTransfers']),
      totalCommission: d(json['totalCommission']),
      totalTransferCount: (json['totalTransferCount'] as num?)?.toInt() ?? 0,
      totalSystemBalance: (json['totalSystemBalance'] as num?)?.toDouble(),
    );
  }
}
