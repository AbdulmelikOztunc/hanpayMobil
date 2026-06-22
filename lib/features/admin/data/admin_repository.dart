import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/network/api_client.dart';
import 'package:hanpay_mobil/shared/models/admin_models.dart';
import 'package:hanpay_mobil/shared/models/balance_models.dart';
import 'package:hanpay_mobil/shared/models/json_helpers.dart';
import 'package:hanpay_mobil/shared/models/state_model.dart';
import 'package:hanpay_mobil/shared/models/user_model.dart';

class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  Future<List<AdminRequestDto>> getRequests() async {
    try {
      final response = await _dio.get<List<dynamic>>('/admin/requests');
      return (response.data ?? [])
          .map((e) => AdminRequestDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> approveRequest(int id) async {
    try {
      await _dio.post<void>('/admin/requests/$id/approve');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> rejectRequest(int id, {String? adminResponse}) async {
    try {
      await _dio.post<void>(
        '/admin/requests/$id/reject',
        data: adminResponse == null || adminResponse.trim().isEmpty
            ? null
            : {'adminResponse': adminResponse.trim()},
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> resolveTransferCancellationRequest(
    int id, {
    required String action,
    required String adminNote,
    int? commissionSettlement,
    int? targetStateId,
  }) async {
    try {
      await _dio.post<void>(
        '/admin/requests/$id/resolve-cancellation',
        data: {
          'action': action,
          'adminNote': adminNote,
          if (commissionSettlement != null) 'commissionSettlement': commissionSettlement,
          if (targetStateId != null) 'targetStateId': targetStateId,
        },
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<AdminTransferRow>> getTransfers({
    String? search,
    String? status,
    String? fromUtc,
    String? toUtc,
    int? take,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/admin/transfers',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          if (fromUtc != null) 'fromUtc': fromUtc,
          if (toUtc != null) 'toUtc': toUtc,
          if (take != null) 'take': take,
        },
      );
      return (response.data ?? [])
          .map((e) => AdminTransferRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<AdminAgentDto>> getAgents() async {
    try {
      final response = await _dio.get<List<dynamic>>('/agents/list');
      return (response.data ?? [])
          .map((e) => AdminAgentDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AdminAgentDto> getAgent(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/agents/$id');
      return AdminAgentDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<AdminDistributorDto>> getDistributors() async {
    try {
      final response = await _dio.get<List<dynamic>>('/distributors');
      return (response.data ?? [])
          .map((e) => AdminDistributorDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AdminDistributorDto> getDistributor(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/distributors/$id');
      return AdminDistributorDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<AppUserDto>> getUsers({String? role}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/users',
        queryParameters: role == null ? null : {'role': role},
      );
      return (response.data ?? [])
          .map((e) => AppUserDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<StateDto>> getStates() async {
    try {
      final response = await _dio.get<List<dynamic>>('/states');
      return (response.data ?? [])
          .map((e) => StateDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<StateDto> createState({required String name, required String code}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/states', data: {
        'name': name,
        'code': code,
      });
      return StateDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<StateDto> getStateById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/states/$id');
      return StateDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<StateDto> updateState(int id, {required String name, required String code}) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>('/states/$id', data: {
        'name': name,
        'code': code,
      });
      return StateDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteState(int id) async {
    try {
      await _dio.delete<void>('/states/$id');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<double> getMinimumTransferUsd() async {
    try {
      final response = await _dio.get<dynamic>('/transfers/minimum-transfer-usd');
      final data = response.data;
      if (data is num) return data.toDouble();
      if (data is Map) return (data['minimumTransferUsd'] as num?)?.toDouble() ?? 0;
      return 0;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> updateMinimumTransferUsd(double value) async {
    try {
      await _dio.put<void>('/transfers/minimum-transfer-usd', data: {
        'minimumTransferUsd': value,
      });
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<int> getReceiptRetentionDays() async {
    try {
      final response = await _dio.get<dynamic>('/transfers/receipt-retention-days');
      final data = response.data;
      if (data is num) return data.toInt();
      if (data is Map) return (data['receiptRetentionDays'] as num?)?.toInt() ?? 0;
      return 0;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> updateReceiptRetentionDays(int value) async {
    try {
      await _dio.put<void>('/transfers/receipt-retention-days', data: {
        'receiptRetentionDays': value,
      });
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<RoleDto>> getRoles() async {
    try {
      final response = await _dio.get<List<dynamic>>('/roles');
      return (response.data ?? [])
          .map((e) => RoleDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<CashboxesSummary> getCashboxes({String? fromUtc, String? toUtc}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/cashboxes',
        queryParameters: {
          if (fromUtc != null) 'fromUtc': fromUtc,
          if (toUtc != null) 'toUtc': toUtc,
        },
      );
      return CashboxesSummary.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<DistributorPrimRow>> getAllPrims({
    int? year,
    int? month,
    int? distributorId,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/distributors/prims',
        queryParameters: {
          if (year != null) 'year': year,
          if (month != null) 'month': month,
          if (distributorId != null) 'distributorId': distributorId,
        },
      );
      return (response.data ?? [])
          .map((e) => DistributorPrimRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<PrimPackageRow>> getPrimPackages() async {
    try {
      final response = await _dio.get<List<dynamic>>('/distributor-prim-packages');
      return (response.data ?? [])
          .map((e) => PrimPackageRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<PrimPackageDetail> getPrimPackage(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/distributor-prim-packages/$id');
      return PrimPackageDetail.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<PrimPackageDetail> createPrimPackage(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/distributor-prim-packages', data: body);
      return PrimPackageDetail.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<PrimPackageDetail> updatePrimPackage(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>('/distributor-prim-packages/$id', data: body);
      return PrimPackageDetail.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deletePrimPackage(int id) async {
    try {
      await _dio.delete<void>('/distributor-prim-packages/$id');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AdminAgentDto> createAgent(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/agents', data: body);
      return AdminAgentDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AdminAgentDto> updateAgent(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>('/agents/$id', data: body);
      return AdminAgentDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteAgent(int id) async {
    try {
      await _dio.delete<void>('/agents/$id');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> reactivateAgent(int id) async {
    try {
      await _dio.post<void>('/agents/$id/reactivate');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AgentDetailStatistics?> getAgentSummary(int agentId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/agents/$agentId/summary');
      final data = response.data;
      if (data == null || data.isEmpty) return null;
      return AgentDetailStatistics.fromJson(data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<AgentTransactionRow>> getAgentTransactions(int agentId) async {
    try {
      final response = await _dio.get<List<dynamic>>('/agents/$agentId/transactions');
      return (response.data ?? [])
          .map((e) => AgentTransactionRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AdminDistributorDto> createDistributor(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/distributors', data: body);
      return AdminDistributorDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AdminDistributorDto> updateDistributor(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>('/distributors/$id', data: body);
      return AdminDistributorDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteDistributor(int id) async {
    try {
      await _dio.delete<void>('/distributors/$id');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<AgentTransactionRow>> getDistributorBalanceHistory(int id) async {
    try {
      final response = await _dio.get<List<dynamic>>('/distributors/$id/balance/history');
      return (response.data ?? [])
          .map((e) => AgentTransactionRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<DistributorPrimRow>?> getDistributorEarnedPrims(int distributorId) async {
    try {
      final response = await _dio.get<List<dynamic>>('/distributors/$distributorId/prims');
      return (response.data ?? [])
          .map((e) => DistributorPrimRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw mapDioException(e);
    }
  }

  Future<double> creditDistributorBalance(int id, {required double amount, String? description}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/distributors/$id/balance/credit',
        data: {'amount': amount, 'description': description ?? ''},
      );
      return jsonDouble((response.data ?? {})['balance']);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<double> debitDistributorBalance(int id, {required double amount, String? description}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/distributors/$id/balance/debit',
        data: {'amount': amount, 'description': description ?? ''},
      );
      return jsonDouble((response.data ?? {})['balance']);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AppUserDto> getUser(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/$id');
      return AppUserDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/users', data: body);
      return response.data ?? {};
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> body) async {
    try {
      await _dio.put<void>('/users/$id', data: body);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _dio.delete<void>('/users/$id');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> assignUser(int userId, {int? agentId, int? distributorId}) async {
    try {
      await _dio.post<void>(
        '/users/$userId/assign',
        data: {
          if (agentId != null) 'agentId': agentId,
          if (distributorId != null) 'distributorId': distributorId,
        },
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> unassignUser(int userId) async {
    try {
      await _dio.post<void>('/users/$userId/unassign');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<String>> getPermissionsCatalog() async {
    try {
      final response = await _dio.get<List<dynamic>>('/permissions');
      return (response.data ?? []).map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<PermissionsMatrix> getPermissionsMatrix() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/roles/permissions-matrix');
      final data = response.data ?? {};
      return data.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        ),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<String>> getRolePermissions(int roleId) async {
    try {
      final response = await _dio.get<List<dynamic>>('/roles/$roleId/permissions');
      return (response.data ?? []).map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<String>> updateRolePermissions(int roleId, List<String> permissions) async {
    try {
      final response = await _dio.put<List<dynamic>>(
        '/roles/$roleId/permissions',
        data: {'permissions': permissions},
      );
      return (response.data ?? []).map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<ManualCashboxResult> recordUserManualMovement(
    int userId, {
    required double amount,
    required String description,
    required int direction,
    int source = 2,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/cashboxes/users/$userId/manual-movement',
        data: {
          'amount': amount,
          'direction': direction,
          'source': source,
          'description': description,
        },
      );
      final data = response.data ?? {};
      return ManualCashboxResult(
        centralBalance: jsonDouble(data['centralBalance'] ?? data['CentralBalance']),
        userBalance: jsonDouble(data['userBalance'] ?? data['UserBalance']),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(dioProvider));
});
