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
  });

  final int id;
  final String type;
  final String status;
  final DateTime createdAt;
  final int? transferId;
  final String? transferNumber;
  final String? reason;
  final String? requestedByName;

  factory AdminRequestDto.fromJson(Map<String, dynamic> json) => AdminRequestDto(
        id: jsonInt(json['id']),
        type: jsonStr(json['type']),
        status: jsonStr(json['status']),
        createdAt: jsonDate(json['createdAt']),
        transferId: (json['transferId'] as num?)?.toInt(),
        transferNumber: json['transferNumber'] as String?,
        reason: json['reason'] as String? ?? json['cancellationReason'] as String?,
        requestedByName: json['requestedByName'] as String? ?? json['requesterName'] as String?,
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
