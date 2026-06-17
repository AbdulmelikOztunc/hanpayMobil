import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/network/api_client.dart';
import 'package:hanpay_mobil/shared/models/balance_models.dart';
import 'package:hanpay_mobil/shared/models/user_model.dart';

class DistributorRepository {
  DistributorRepository(this._dio);

  final Dio _dio;

  Future<DistributorBalanceSummary> getBalance({int? year, int? month}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/distributor/balance',
        queryParameters: year != null && month != null ? {'year': year, 'month': month} : null,
      );
      return DistributorBalanceSummary.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<DistributorPrimRow>> getMyPrims({int? year, int? month}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/distributor/prims',
        queryParameters: year != null && month != null ? {'year': year, 'month': month} : null,
      );
      return (response.data ?? [])
          .map((e) => DistributorPrimRow.fromJson(e as Map<String, dynamic>))
          .toList();
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
}

final distributorRepositoryProvider = Provider<DistributorRepository>((ref) {
  return DistributorRepository(ref.watch(dioProvider));
});
