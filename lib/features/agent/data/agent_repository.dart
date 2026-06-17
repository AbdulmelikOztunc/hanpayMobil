import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/network/api_client.dart';
import 'package:hanpay_mobil/shared/models/balance_models.dart';
import 'package:hanpay_mobil/shared/models/state_model.dart';
import 'package:hanpay_mobil/shared/models/user_model.dart';

class AgentRepository {
  AgentRepository(this._dio);

  final Dio _dio;

  Future<AgentBalanceSummary> getBalance({int? year, int? month}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/agent/balance',
        queryParameters: year != null && month != null ? {'year': year, 'month': month} : null,
      );
      return AgentBalanceSummary.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<AppUserDto>> getUsers() async {
    try {
      final response = await _dio.get<List<dynamic>>('/users');
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
}

final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return AgentRepository(ref.watch(dioProvider));
});
