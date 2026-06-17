import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/env.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/core/network/auth_token_holder.dart';
import 'package:hanpay_mobil/features/auth/presentation/auth_controller.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._read);

  final Ref _read;

  bool _isAnonymousAuth(RequestOptions options) {
    final path = options.uri.path.toLowerCase();
    return path.endsWith('/auth/login') ||
        path.endsWith('/auth/forgot-password') ||
        path.endsWith('/auth/reset-password');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isAnonymousAuth(options)) {
      final token = _read.read(authTokenHolderProvider).token;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (options.data is FormData) {
      options.headers.remove('Content-Type');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final path = err.requestOptions.uri.path.toLowerCase();
    final isLogin = path.endsWith('/auth/login');
    final isChangePassword = path.endsWith('/auth/change-password');

    if (status == 401 && !isLogin && !isChangePassword) {
      _read.read(authControllerProvider.notifier).logout(localOnly: true);
    }

    handler.next(err);
  }
}

Dio createDio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: ApiException('Bağlantı zaman aşımına uğradı.'),
            ),
          );
          return;
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}

ApiException mapDioException(DioException error) {
  final data = error.response?.data;
  var message = 'Bir hata oluştu.';

  if (data is Map) {
    message = (data['message'] ?? data['title'] ?? data['detail'])?.toString() ?? message;
  } else if (data is String && data.isNotEmpty) {
    message = data;
  } else if (error.message != null) {
    message = error.message!;
  }

  if (error.response?.statusCode == 401) {
    message = 'E-posta veya şifre hatalı.';
  } else if (error.response?.statusCode == 403) {
    message = 'Bu işlem için yetkiniz yok.';
  }

  return ApiException(message, statusCode: error.response?.statusCode, details: data);
}

final dioProvider = Provider<Dio>((ref) => createDio(ref));
