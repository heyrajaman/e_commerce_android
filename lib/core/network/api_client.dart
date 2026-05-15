import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../shared/services/storage_service.dart';

class ApiClient {
  late final Dio dio;
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

  Future<void> init() async {
    dio.interceptors.add(AuthInterceptor(getCsrfToken: () => _csrfToken));

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
    } catch (e, stack) {
      developer.log(
        'CSRF initialization failed',
        error: e,
        stackTrace: stack,
        name: 'ApiClient',
      );
    }
  }

  Future<void> fetchCsrfToken() async {
    try {
      final response = await dio.get('/api/auth/csrf-token');

      // SONARQUBE FIX: Explicit Type Checking to prevent HTML/String crashes
      if (response.data != null && response.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        if (data['csrfToken'] != null) {
          _csrfToken = data['csrfToken'].toString();
        }
      }
    } catch (e, stack) {
      developer.log(
        'Failed to fetch CSRF token',
        error: e,
        stackTrace: stack,
        name: 'ApiClient',
      );
    }
  }

  String? get csrfToken => _csrfToken;
}

class AuthInterceptor extends Interceptor {
  final String? Function() getCsrfToken;

  AuthInterceptor({required this.getCsrfToken});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final storageService = GetIt.I<StorageService>();
    final token = await storageService.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    final csrf = getCsrfToken();
    if (csrf != null && csrf.isNotEmpty) {
      options.headers['x-csrf-token'] = csrf;
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    if (statusCode == 401) {
      developer.log(
        'Unauthorized (401) detected. Forcing user logout.',
        name: 'AuthInterceptor',
      );

      final storageService = GetIt.I<StorageService>();
      await storageService.deleteToken();
      await storageService.clearAll();

      try {
        final router = GetIt.I<GoRouter>();
        // PROD ROUTING FIX: Use named route to prevent hardcoded path crashes
        router.goNamed('login');
      } catch (e, stack) {
        developer.log(
          'Failed to route to login on 401 error',
          error: e,
          stackTrace: stack,
          name: 'AuthInterceptor',
        );
      }
    }

    return handler.next(err);
  }
}
