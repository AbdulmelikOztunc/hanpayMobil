import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/network/api_client.dart';
import 'package:hanpay_mobil/shared/models/insights_models.dart';

class InsightsRepository {
  InsightsRepository(this._dio);

  final Dio _dio;

  Future<PaymentDistributionDto> getPaymentDistribution({
    int? year,
    int? month,
    String? fromUtc,
    String? toUtc,
    int? agentId,
    int? distributorId,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (fromUtc != null && toUtc != null) {
        params['fromUtc'] = fromUtc;
        params['toUtc'] = toUtc;
      } else if (year != null && month != null) {
        params['year'] = year;
        params['month'] = month;
      }
      if (agentId != null) params['agentId'] = agentId;
      if (distributorId != null) params['distributorId'] = distributorId;

      final response = await _dio.get<Map<String, dynamic>>(
        '/insights/statistics/payment-distribution',
        queryParameters: params.isEmpty ? null : params,
      );
      return PaymentDistributionDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<MonthlyTransferVolumeDto> getMonthlyTransferVolume({
    int months = 6,
    int? agentId,
    int? distributorId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/insights/statistics/monthly-transfer-volume',
        queryParameters: {
          'months': months,
          if (agentId != null) 'agentId': agentId,
          if (distributorId != null) 'distributorId': distributorId,
        },
      );
      return MonthlyTransferVolumeDto.fromJson(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<TransferReportRow>> getTransferReport({
    String? fromUtc,
    String? toUtc,
    String? period,
    int? agentId,
    int? distributorId,
    String? status,
    int? stateId,
    int? take,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/insights/reports/transfers',
        queryParameters: {
          if (fromUtc != null) 'fromUtc': fromUtc,
          if (toUtc != null) 'toUtc': toUtc,
          if (period != null) 'period': period,
          if (agentId != null) 'agentId': agentId,
          if (distributorId != null) 'distributorId': distributorId,
          if (status != null) 'status': status,
          if (stateId != null) 'stateId': stateId,
          if (take != null) 'take': take,
        },
      );
      return (response.data ?? [])
          .map((e) => TransferReportRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return InsightsRepository(ref.watch(dioProvider));
});
