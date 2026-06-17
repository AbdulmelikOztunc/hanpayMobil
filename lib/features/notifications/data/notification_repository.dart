import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/network/api_client.dart';
import 'package:hanpay_mobil/shared/models/notification_model.dart';

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<List<AppNotificationDto>> list({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/notifications',
        queryParameters: {
          if (unreadOnly) 'unreadOnly': true,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return (response.data ?? [])
          .map((e) => AppNotificationDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/notifications/unread-count');
      final data = response.data ?? {};
      return (data['count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _dio.patch<void>('/notifications/$id/read');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.patch<void>('/notifications/read-all');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(notificationRepositoryProvider).unreadCount();
});
