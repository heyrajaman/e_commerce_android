import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../shared/services/storage_service.dart';
import '../error/exceptions.dart';

class ApiClient {
  late final Dio dio;

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

    // Add Authentication and Error Handling Interceptor
    dio.interceptors.add(AuthInterceptor());

    // Add Logging Interceptor only in Debug Mode
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
  }
}

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Inject JWT token from local storage
    final storageService = GetIt.I<StorageService>();
    final token = await storageService.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    // Attempt to extract the backend's standard JSON error message if available
    final data = err.response?.data;
    String errorMessage = 'An unexpected error occurred';
    if (data is Map<String, dynamic> && data.containsKey('message')) {
      errorMessage = data['message'];
    } else if (err.message != null) {
      errorMessage = err.message!;
    }

    // Handle 401 Unauthorized (Token expired or invalid)
    if (statusCode == 401) {
      final storageService = GetIt.I<StorageService>();
      await storageService.deleteToken();
      await storageService.clearAll();

      // Redirect to login using GoRouter
      try {
        final router = GetIt.I<GoRouter>();
        router.go('/login');
      } catch (_) {
        // Router might not be ready during app initialization
      }
    }

    // Map the Dio exception to our custom domain exceptions
    final customException = ApiExceptionMapper.map(statusCode, errorMessage);

    // Pass the custom exception forward
    final customErr = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      error: customException,
      type: DioExceptionType.unknown,
    );

    return handler.next(customErr);
  }
}