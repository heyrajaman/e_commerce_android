import 'dart:convert';

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
    if (e.response?.data != null && e.response?.data is Map) {
      final responseData = e.response!.data as Map;

      if (responseData['message'] != null) {
        return responseData['message'].toString();
      }
    }
    return e.message ?? 'An unknown error occurred';
  }

  Future<UserModel> login(String phone, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {'phone': phone, 'password': password},
      );

      final userData = response.data['user'] ?? response.data;
      final token = response.data['token'];
      final user = UserModel.fromJson(userData);

      if (token != null) {
        await _storageService.saveToken(token);
      }

      await _storageService.saveUserId(user.id);

      return user;
    } on DioException catch (e) {
      // CRITICAL FIX: Use the helper to get the backend message
      throw ServerException(_extractErrorMessage(e));
    } catch (e) {
      throw ServerException(e.toString());
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

      final userData = response.data['user'] ?? response.data;
      final token = response.data['token'];

      final user = UserModel.fromJson(userData);

      if (token != null) {
        await _storageService.saveToken(token);
      }
      await _storageService.saveUserId(user.id);

      return user;
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiEndpoints.logout);
      await _storageService.deleteToken();
      await _storageService.clearAll();
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<UserModel> getMe() async {
    try {
      // 1. Grab the token from storage
      final token = await _storageService.getToken();
      if (token == null) throw ServerException('No token found');

      // 2. Decode the JWT token to find the user's role
      String role = 'user'; // default to customer
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = base64Url.normalize(parts[1]);
        final String decoded = utf8.decode(base64Url.decode(payload));
        final Map<String, dynamic> tokenData = jsonDecode(decoded);
        role = tokenData['role'] ?? 'user';
      }

      // 3. Route to the correct backend endpoint based on the role!
      if (role == 'delivery_boy') {
        final response = await _apiClient.dio.get(ApiEndpoints.deliveryProfile);

        final Map<String, dynamic> boyData =
            response.data['profile'] ?? response.data;
        boyData['role'] =
            'delivery_boy'; // Re-inject role so the AppRouter knows!

        return UserModel.fromJson(boyData);
      } else {
        final response = await _apiClient.dio.get(ApiEndpoints.me);

        final userData = response.data['user'] ?? response.data;
        return UserModel.fromJson(userData);
      }
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e) {
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
    } catch (e) {
      throw ServerException(e.toString());
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

      // Inject the role so our Flutter state management knows how to route them
      boyData['role'] = 'delivery_boy';
      boyData['phone'] = phone;

      final user = UserModel.fromJson(boyData);

      // Save the user ID just like your regular login
      await _storageService.saveUserId(user.id);

      return user;
    } on DioException catch (e) {
      // Using your custom error extractor!
      throw ServerException(_extractErrorMessage(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
