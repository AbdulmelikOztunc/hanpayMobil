import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/network/api_client.dart';
import 'package:hanpay_mobil/shared/models/dashboard_models.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<AgentDashboard> getAgentDashboard() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/dashboard/agent');
      return AgentDashboard.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<DistributorDashboard> getDistributorDashboard() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/dashboard/distributor');
      return DistributorDashboard.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AdminDashboard> getAdminDashboard() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/dashboard/admin');
      return AdminDashboard.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});
