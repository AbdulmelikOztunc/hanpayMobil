import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/network/api_client.dart';
import 'package:hanpay_mobil/shared/models/balance_models.dart';
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

  Future<String> createTransfer(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/transfers', data: body);
      final data = response.data ?? {};
      return data['transferNumber']?.toString() ?? '';
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<TransferDto> updateTransfer(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>('/transfers/$id', data: body);
      return TransferDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<TransferSummaryQuote> getSummaryQuote({
    required double transferAmountUsd,
    double cashUsd = 0,
    double bankUsd = 0,
    double cashTl = 0,
    double bankTl = 0,
    double discountUsd = 0,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/transfers/summary-quote',
        queryParameters: {
          'transferAmountUsd': transferAmountUsd,
          'cashUsd': cashUsd,
          'bankUsd': bankUsd,
          'cashTl': cashTl,
          'bankTl': bankTl,
          'discountUsd': discountUsd,
        },
      );
      return TransferSummaryQuote.fromJson(response.data ?? {});
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

  Future<void> cancelAsAdmin(int id, {required int commissionSettlement, String? adminNote}) async {
    try {
      await _dio.post<void>('/transfers/$id/cancel', data: {
        'commissionSettlement': commissionSettlement,
        if (adminNote != null && adminNote.isNotEmpty) 'adminNote': adminNote,
      });
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
