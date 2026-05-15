import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/storage_service.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthRepository(this._apiClient, this._storageService);

  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
      final responseData = e.response!.data as Map<String, dynamic>;

      if (responseData['message'] != null) {
        return responseData['message'].toString();
      }
    }
    return e.message ?? 'An unknown network error occurred';
  }

  Future<UserModel> login(String phone, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {'phone': phone, 'password': password},
      );

      final Map<String, dynamic> userData =
          response.data['user'] ?? response.data;
      final String? token = response.data['token'];
      final user = UserModel.fromJson(userData);

      if (token != null) {
        await _storageService.saveToken(token);
      }
      await _storageService.saveUserId(user.id);

      return user;
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'Login mapping error',
        error: e,
        stackTrace: stack,
        name: 'AuthRepository',
      );
      throw ServerException('Failed to process login data.');
    }
  }

  Future<UserModel> register(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        },
      );

      final Map<String, dynamic> userData =
          response.data['user'] ?? response.data;
      final String? token = response.data['token'];
      final user = UserModel.fromJson(userData);

      if (token != null) {
        await _storageService.saveToken(token);
      }
      await _storageService.saveUserId(user.id);

      return user;
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'Registration mapping error',
        error: e,
        stackTrace: stack,
        name: 'AuthRepository',
      );
      throw ServerException('Failed to process registration data.');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiEndpoints.logout);
    } on DioException catch (e, stack) {
      developer.log(
        'Backend logout failed, proceeding with local clear',
        error: e,
        stackTrace: stack,
        name: 'AuthRepository',
      );
    } catch (e, stack) {
      developer.log(
        'Unexpected error during logout',
        error: e,
        stackTrace: stack,
        name: 'AuthRepository',
      );
    } finally {
      // ALWAYS execute this to ensure the app state resets, even if the API call drops
      await _storageService.deleteToken();
      await _storageService.clearAll();
    }
  }

  Future<UserModel> getMe() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) throw ServerException('No active session found.');

      String role = 'user'; // default to customer

      // Safely decode JWT to route correctly without crashing on malformed tokens
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = base64Url.normalize(parts[1]);
          final String decoded = utf8.decode(base64Url.decode(payload));
          final Map<String, dynamic> tokenData = jsonDecode(decoded);
          role = tokenData['role']?.toString() ?? 'user';
        }
      } catch (e, stack) {
        developer.log(
          'Failed to decode JWT payload safely',
          error: e,
          stackTrace: stack,
          name: 'AuthRepository',
        );
      }

      if (role == 'delivery_boy') {
        final response = await _apiClient.dio.get(ApiEndpoints.deliveryProfile);

        final Map<String, dynamic> boyData =
            response.data['profile'] ?? response.data;
        boyData['role'] = 'delivery_boy';
        return UserModel.fromJson(boyData);
      } else {
        final response = await _apiClient.dio.get(ApiEndpoints.me);

        final Map<String, dynamic> userData =
            response.data['user'] ?? response.data;
        return UserModel.fromJson(userData);
      }
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'GetMe mapping error',
        error: e,
        stackTrace: stack,
        name: 'AuthRepository',
      );
      throw ServerException(e.toString());
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.changePassword,
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'Password change error',
        error: e,
        stackTrace: stack,
        name: 'AuthRepository',
      );
      throw ServerException('Failed to change password.');
    }
  }

  Future<UserModel> loginDeliveryBoy(String phone, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.deliveryLogin,
        data: {'phone': phone, 'password': password},
      );

      final Map<String, dynamic> boyData = response.data['boy'];
      final String token = response.data['token'];

      await _storageService.saveToken(token);

      boyData['role'] = 'delivery_boy';
      boyData['phone'] = phone;

      final user = UserModel.fromJson(boyData);
      await _storageService.saveUserId(user.id);

      return user;
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'Delivery boy login mapping error',
        error: e,
        stackTrace: stack,
        name: 'AuthRepository',
      );
      throw ServerException('Failed to process delivery login data.');
    }
  }
}
