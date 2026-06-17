import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/network/api_client.dart';
import 'package:hanpay_mobil/shared/models/transfer.dart';

enum DistributorTab { active, history }

class TransferRepository {
  TransferRepository(this._dio);

  final Dio _dio;

  // ---------- Agent ----------

  Future<List<TransferDto>> getMyAgentTransfers() async {
    try {
      final response = await _dio.get<List<dynamic>>('/transfers/agent/my-transfers');
      return (response.data ?? [])
          .map((e) => TransferDto.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<TransferDto> getById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/transfers/$id');
      return TransferDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> createCancellationRequest(int id, {required String reason}) async {
    try {
      await _dio.post<void>(
        '/transfers/$id/cancellation-requests',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ---------- Distributor ----------

  Future<List<TransferDto>> getDistributorTransfers(DistributorTab tab) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/transfers/distributor/transfers',
        queryParameters: {'tab': tab.name},
      );
      return (response.data ?? [])
          .map((e) => TransferDto.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<TransferDto> claim(int id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/transfers/$id/claim');
      return TransferDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<TransferDto> complete(int id) async {
    try {
      final response =
          await _dio.post<Map<String, dynamic>>('/transfers/$id/distributor/complete');
      return TransferDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<TransferDto> reject(int id) async {
    try {
      final response =
          await _dio.post<Map<String, dynamic>>('/transfers/$id/distributor/reject');
      return TransferDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<TransferDto> uploadReceipt(int id, {required String filePath}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/transfers/$id/distributor/receipt',
        data: formData,
      );
      return TransferDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  return TransferRepository(ref.watch(dioProvider));
});
