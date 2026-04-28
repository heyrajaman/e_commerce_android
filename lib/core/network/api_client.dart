import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../config/app_config.dart';
import '../../shared/services/storage_service.dart';
import '../error/exceptions.dart';

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
        },
      ),
    );
  }

  // Mobile apps need to find the device's storage directory to save cookies
  Future<void> init() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final cookiePath = '${appDocDir.path}/cookies';
    cookieJar = PersistCookieJar(storage: FileStorage(cookiePath));

    // 1. Add CookieManager FIRST so it handles all httpOnly cookies automatically
    dio.interceptors.add(CookieManager(cookieJar));

    // 2. Add our custom Auth & CSRF Interceptor
    dio.interceptors.add(AuthCsrfInterceptor(this));

    // 3. Add Logging in Debug Mode
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

    // 4. Fetch the initial CSRF token from your backend
    await fetchCsrfToken();
  }

  Future<void> fetchCsrfToken() async {
    try {
      // This matches your backend route: app.get("/api/auth/csrf-token", ...)
      final response = await dio.get('/auth/csrf-token');
      if (response.data != null && response.data['csrfToken'] != null) {
        _csrfToken = response.data['csrfToken'];
      }
    } catch (e) {
      debugPrint('Failed to fetch CSRF token: $e');
    }
  }

  String? get csrfToken => _csrfToken;
}

class AuthCsrfInterceptor extends Interceptor {
  final ApiClient apiClient;

  AuthCsrfInterceptor(this.apiClient);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Inject X-CSRF-Token header for mutation requests (POST, PUT, DELETE, PATCH)
    // to satisfy your backend's csurf protection
    if ([
      'POST',
      'PUT',
      'PATCH',
      'DELETE',
    ].contains(options.method.toUpperCase())) {
      if (apiClient.csrfToken != null) {
        options.headers['X-CSRF-Token'] = apiClient.csrfToken;
      }
    }

    // Fallback: If you ever save a normal token manually, we attach it.
    // Otherwise, the CookieManager handles the httpOnly JWT automatically!
    final storageService = GetIt.I<StorageService>();
    final token = await storageService.getToken();
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
    final data = err.response?.data;

    String errorMessage = 'An unexpected error occurred';
    if (data is Map<String, dynamic> && data.containsKey('message')) {
      errorMessage = data['message'];
    } else if (err.message != null) {
      errorMessage = err.message!;
    }

    // If CSRF is invalid or missing, fetch a fresh one
    if (statusCode == 403 && errorMessage.toLowerCase().contains('csrf')) {
      await apiClient.fetchCsrfToken();
    }

    // Handle Unauthorized
    if (statusCode == 401) {
      final storageService = GetIt.I<StorageService>();
      await storageService.deleteToken();
      await storageService.clearAll();

      // Wipe the httpOnly cookies from the device
      await apiClient.cookieJar.deleteAll();

      try {
        final router = GetIt.I<GoRouter>();
        router.go('/login');
      } catch (_) {}
    }

    final customException = ApiExceptionMapper.map(statusCode, errorMessage);
    final customErr = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      error: customException,
      type: DioExceptionType.unknown,
    );

    return handler.next(customErr);
  }
}
