import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/network/api_client.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/core/storage/session_storage.dart';
import 'package:hanpay_mobil/shared/models/auth_session.dart';

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SessionStorage _storage;

  Future<AuthSession> login({required String email, required String password}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final session = AuthSession.fromApiResponse(response.data ?? {});
      if (session.token.isEmpty) {
        throw ApiException('Giriş yanıtında token bulunamadı.');
      }
      await _storage.saveSession(session.encode());
      return session;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AuthSession> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      final session = AuthSession.fromApiResponse(response.data ?? {});
      if (session.token.isEmpty) {
        throw ApiException('Şifre değiştirme yanıtında token bulunamadı.');
      }
      await _storage.saveSession(session.encode());
      return session;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<String?> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email},
      );
      final data = response.data ?? {};
      return data['token']?.toString() ?? data['resetToken']?.toString();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AuthSession> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {
          'email': email,
          'token': token,
          'newPassword': newPassword,
        },
      );
      final session = AuthSession.fromApiResponse(response.data ?? {});
      if (session.token.isEmpty) {
        throw ApiException('Şifre sıfırlama yanıtında token bulunamadı.');
      }
      await _storage.saveSession(session.encode());
      return session;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> logoutRemote() async {
    try {
      await _dio.post<void>('/auth/logout');
    } catch (_) {
      // Token expired etc. — local session still cleared by caller.
    }
  }

  Future<AuthSession?> restoreSession() async {
    final raw = await _storage.readSession();
    return AuthSession.decode(raw);
  }

  Future<void> clearSession() => _storage.clearSession();
}

final sessionStorageProvider = Provider<SessionStorage>((ref) => SessionStorage());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(sessionStorageProvider));
});
