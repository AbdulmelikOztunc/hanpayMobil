import 'package:hanpay_mobil/shared/models/json_helpers.dart';
import 'package:hanpay_mobil/shared/models/transfer.dart';

class AdminRequestDto {
  const AdminRequestDto({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    this.transferId,
    this.transferNumber,
    this.reason,
    this.requestedByName,
    this.transferState,
    this.transferStateId,
    this.netCommissionUsd,
  });

  final int id;
  final String type;
  final String status;
  final DateTime createdAt;
  final int? transferId;
  final String? transferNumber;
  final String? reason;
  final String? requestedByName;
  final String? transferState;
  final int? transferStateId;
  final double? netCommissionUsd;

  bool get isCancellationRequest =>
      type.toLowerCase().contains('cancellation') || type.toLowerCase().contains('iptal');

  factory AdminRequestDto.fromJson(Map<String, dynamic> json) => AdminRequestDto(
        id: jsonInt(json['id']),
        type: jsonStr(json['type']),
        status: jsonStr(json['status']),
        createdAt: jsonDate(json['createdAt']),
        transferId: (json['transferId'] as num?)?.toInt(),
        transferNumber: json['transferNumber'] as String?,
        reason: json['reason'] as String? ??
            json['cancellationReason'] as String? ??
            json['description'] as String?,
        requestedByName: json['requestedByName'] as String? ??
            json['requesterName'] as String? ??
            json['createdByUserName'] as String? ??
            json['user'] as String?,
        transferState: json['transferState'] as String?,
        transferStateId: (json['transferStateId'] as num?)?.toInt(),
        netCommissionUsd: (json['netCommissionUsd'] as num?)?.toDouble(),
      );
}

class AdminAgentDto {
  const AdminAgentDto({
    required this.id,
    required this.name,
    required this.code,
    required this.balance,
    required this.isActive,
    this.commissionRate,
    this.creditLimit,
  });

  final int id;
  final String name;
  final String code;
  final double balance;
  final bool isActive;
  final double? commissionRate;
  final double? creditLimit;

  factory AdminAgentDto.fromJson(Map<String, dynamic> json) => AdminAgentDto(
        id: jsonInt(json['id']),
        name: jsonStr(json['name']),
        code: jsonStr(json['code']),
        balance: jsonDouble(json['balance'] ?? json['accountBalance']),
        isActive: json['isActive'] != false && json['isDeleted'] != true,
        commissionRate: (json['commissionRate'] as num?)?.toDouble(),
        creditLimit: (json['creditLimit'] as num?)?.toDouble(),
      );
}

class AdminDistributorDto {
  const AdminDistributorDto({
    required this.id,
    required this.name,
    required this.code,
    required this.balance,
    required this.isActive,
    this.stateName,
  });

  final int id;
  final String name;
  final String code;
  final double balance;
  final bool isActive;
  final String? stateName;

  factory AdminDistributorDto.fromJson(Map<String, dynamic> json) => AdminDistributorDto(
        id: jsonInt(json['id']),
        name: jsonStr(json['name']),
        code: jsonStr(json['code']),
        balance: jsonDouble(json['balance'] ?? json['accountBalance']),
        isActive: json['isActive'] != false && json['isDeleted'] != true,
        stateName: json['stateName'] as String? ?? json['state'] as String?,
      );
}

class AdminTransferRow {
  const AdminTransferRow({
    required this.id,
    required this.transferNumber,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.agentName,
    this.distributorName,
    this.receiverFullName,
  });

  final int id;
  final String transferNumber;
  final double amount;
  final TransferStatus status;
  final DateTime createdAt;
  final String? agentName;
  final String? distributorName;
  final String? receiverFullName;

  factory AdminTransferRow.fromJson(Map<String, dynamic> json) => AdminTransferRow(
        id: jsonInt(json['id']),
        transferNumber: jsonStr(json['transferNumber']),
        amount: jsonDouble(json['amount']),
        status: parseTransferStatus(json['status']),
        createdAt: jsonDate(json['createdAt']),
        agentName: json['agentName'] as String? ?? json['createdByAgentName'] as String?,
        distributorName: json['distributorName'] as String? ?? json['assignedDistributorName'] as String?,
        receiverFullName: json['receiverFullName'] as String?,
      );
}

class RoleDto {
  const RoleDto({required this.id, required this.name, required this.permissions});

  final int id;
  final String name;
  final List<String> permissions;

  factory RoleDto.fromJson(Map<String, dynamic> json) => RoleDto(
        id: jsonInt(json['id']),
        name: jsonStr(json['name']),
        permissions: (json['permissions'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

class CashboxesSummary {
  const CashboxesSummary({
    required this.centralBalance,
    required this.currency,
    required this.netSystemAsset,
    required this.userCashboxes,
  });

  final double centralBalance;
  final String currency;
  final double netSystemAsset;
  final List<UserCashboxRow> userCashboxes;

  factory CashboxesSummary.fromJson(Map<String, dynamic> json) {
    final central = json['centralCashbox'] as Map<String, dynamic>? ?? {};
    final users = (json['userCashboxes'] as List<dynamic>? ?? [])
        .map((e) => UserCashboxRow.fromJson(e as Map<String, dynamic>))
        .toList();
    final net = json['netSystemAsset'] as Map<String, dynamic>?;
    return CashboxesSummary(
      centralBalance: jsonDouble(central['balance']),
      currency: jsonStr(central['currency']).isEmpty ? 'USD' : jsonStr(central['currency']),
      netSystemAsset: jsonDouble(net?['amount'] ?? net?['balance']),
      userCashboxes: users,
    );
  }
}

class UserCashboxRow {
  const UserCashboxRow({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.balance,
  });

  final int userId;
  final String fullName;
  final String email;
  final String role;
  final double balance;

  factory UserCashboxRow.fromJson(Map<String, dynamic> json) => UserCashboxRow(
        userId: jsonInt(json['userId']),
        fullName: jsonStr(json['fullName']),
        email: jsonStr(json['email']),
        role: jsonStr(json['role']),
        balance: jsonDouble(json['balance']),
      );
}

class PrimPackageRow {
  const PrimPackageRow({
    required this.id,
    required this.name,
    required this.isActive,
    this.distributorName,
  });

  final int id;
  final String name;
  final bool isActive;
  final String? distributorName;

  factory PrimPackageRow.fromJson(Map<String, dynamic> json) => PrimPackageRow(
        id: jsonInt(json['id']),
        name: jsonStr(json['name']),
        isActive: json['isActive'] != false,
        distributorName: json['distributorName'] as String?,
      );
}

class PrimPackageBracket {
  const PrimPackageBracket({
    required this.minAmountUsd,
    required this.maxAmountUsd,
    required this.primUsdPerTransfer,
    required this.sortOrder,
  });

  final double minAmountUsd;
  final double maxAmountUsd;
  final double primUsdPerTransfer;
  final int sortOrder;

  factory PrimPackageBracket.fromJson(Map<String, dynamic> json) => PrimPackageBracket(
        minAmountUsd: jsonDouble(json['minAmountUsd']),
        maxAmountUsd: jsonDouble(json['maxAmountUsd']),
        primUsdPerTransfer: jsonDouble(json['primUsdPerTransfer']),
        sortOrder: jsonInt(json['sortOrder']),
      );
}

class PrimPackageDetail {
  const PrimPackageDetail({
    required this.id,
    required this.name,
    required this.isActive,
    required this.brackets,
  });

  final int id;
  final String name;
  final bool isActive;
  final List<PrimPackageBracket> brackets;

  factory PrimPackageDetail.fromJson(Map<String, dynamic> json) => PrimPackageDetail(
        id: jsonInt(json['id']),
        name: jsonStr(json['name']),
        isActive: json['isActive'] != false,
        brackets: (json['brackets'] as List<dynamic>? ?? [])
            .map((e) => PrimPackageBracket.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ManualCashboxResult {
  const ManualCashboxResult({required this.centralBalance, required this.userBalance});

  final double centralBalance;
  final double userBalance;
}

class AgentDetailStatistics {
  const AgentDetailStatistics({
    required this.totalTransfers,
    required this.totalAmount,
    required this.paidCount,
    required this.cancelledCount,
    required this.pendingCount,
    required this.onHoldCount,
    required this.successRate,
    required this.cancelRate,
    required this.unsuccessfulRate,
    required this.byState,
  });

  final int totalTransfers;
  final double totalAmount;
  final int paidCount;
  final int cancelledCount;
  final int pendingCount;
  final int onHoldCount;
  final double successRate;
  final double cancelRate;
  final double unsuccessfulRate;
  final List<AgentStateStatRow> byState;

  factory AgentDetailStatistics.fromJson(Map<String, dynamic> json) {
    final paid = jsonInt(json['paidCount'] ?? json['PaidCount']);
    final cancelled = jsonInt(json['cancelledCount'] ?? json['CancelledCount']);
    final pending = jsonInt(json['pendingCount'] ?? json['PendingCount']);
    final onHold = jsonInt(json['onHoldCount'] ?? json['OnHoldCount']);
    var total = jsonInt(
      json['totalTransfers'] ?? json['TotalTransfers'] ?? json['totalTransactions'] ?? json['TotalTransactions'],
    );
    if (total <= 0) total = paid + cancelled + pending + onHold;

    final byStateRaw = json['byState'] ?? json['ByState'];
    final byState = (byStateRaw is List ? byStateRaw : const [])
        .whereType<Map>()
        .map((e) => AgentStateStatRow.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.state.isNotEmpty)
        .toList();

    return AgentDetailStatistics(
      totalTransfers: total,
      totalAmount: jsonDouble(json['totalAmount'] ?? json['TotalAmount']),
      paidCount: paid,
      cancelledCount: cancelled,
      pendingCount: pending,
      onHoldCount: onHold,
      successRate: total > 0 ? (paid / total) * 100 : 0,
      cancelRate: total > 0 ? (cancelled / total) * 100 : 0,
      unsuccessfulRate: total > 0 ? ((cancelled + onHold) / total) * 100 : 0,
      byState: byState,
    );
  }
}

class AgentStateStatRow {
  const AgentStateStatRow({required this.state, required this.transfers, required this.volume});

  final String state;
  final int transfers;
  final double volume;

  factory AgentStateStatRow.fromJson(Map<String, dynamic> json) => AgentStateStatRow(
        state: jsonStr(json['state'] ?? json['State'] ?? json['stateCode'] ?? json['StateCode']),
        transfers: jsonInt(json['transfers'] ?? json['Transfers'] ?? json['transferCount'] ?? json['TransferCount']),
        volume: jsonDouble(json['volume'] ?? json['Volume'] ?? json['amount'] ?? json['Amount']),
      );
}

class AgentTransactionRow {
  const AgentTransactionRow({
    required this.id,
    required this.date,
    required this.amount,
    required this.transactionType,
    required this.description,
    required this.performedByName,
    required this.balanceAfter,
  });

  final int id;
  final DateTime date;
  final double amount;
  final String transactionType;
  final String description;
  final String performedByName;
  final double balanceAfter;

  factory AgentTransactionRow.fromJson(Map<String, dynamic> json) => AgentTransactionRow(
        id: jsonInt(json['id']),
        date: jsonDate(json['date'] ?? json['createdAt']),
        amount: jsonDouble(json['amount']),
        transactionType: jsonStr(json['transactionType'] ?? json['type']),
        description: jsonStr(json['description']),
        performedByName: jsonStr(json['performedByName']),
        balanceAfter: jsonDouble(json['balanceAfter']),
      );
}

typedef PermissionsMatrix = Map<String, List<String>>;
