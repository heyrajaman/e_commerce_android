import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<UserModel> login(String phone, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {'phone': phone, 'password': password},
      );

      // Depending on your backend response structure, it might be inside a 'user' key
      final userData = response.data['user'] ?? response.data;
      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Unknown error occurred');
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
      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Unknown error occurred');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Unknown error occurred');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.me);

      final userData = response.data['user'] ?? response.data;
      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Unknown error occurred');
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
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Unknown error occurred');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
