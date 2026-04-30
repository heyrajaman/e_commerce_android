import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../shared/services/storage_service.dart';

class ApiClient {
  late final Dio dio;
  late final PersistCookieJar cookieJar;
  String? _csrfToken;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.kBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Client': 'mobile',
        },
      ),
    );
  }

  // Mobile apps need to find the device's storage directory to save cookies
  Future<void> init() async {
    dio.interceptors.add(AuthInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
        ),
      );
    }

    try {
      await fetchCsrfToken();
    } catch (e) {
      debugPrint('CSRF initialization failed: $e');
    }
  }

  Future<void> fetchCsrfToken() async {
    try {
      // This matches your backend route: app.get("/api/auth/csrf-token", ...)
      final response = await dio.get('/api/auth/csrf-token');
      if (response.data != null && response.data['csrfToken'] != null) {
        _csrfToken = response.data['csrfToken'];
      }
    } catch (e) {
      debugPrint('Failed to fetch CSRF token: $e');
    }
  }

  String? get csrfToken => _csrfToken;
}

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final storageService = GetIt.I<StorageService>();
    final token = await storageService.getToken();

    // Inject Bearer token
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    // Handle Unauthorized
    if (statusCode == 401) {
      final storageService = GetIt.I<StorageService>();
      await storageService.deleteToken();
      await storageService.clearAll();

      try {
        final router = GetIt.I<GoRouter>();
        router.go('/login');
      } catch (_) {}
    }

    return handler.next(err);
  }
}
