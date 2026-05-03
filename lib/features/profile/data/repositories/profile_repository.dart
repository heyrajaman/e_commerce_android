import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/user_model.dart';

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<UserModel> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/api/auth/me');
      final data = response.data['user'] ?? response.data;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(
              e.response?.data['message'] ?? 'Failed to fetch profile',
            );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<UserModel> updateProfile(String email, File? imageFile) async {
    try {
      final formData = FormData.fromMap({'email': email});

      if (imageFile != null) {
        formData.files.add(
          MapEntry(
            'profilePic',
            await MultipartFile.fromFile(
              imageFile.path,
              filename: imageFile.path.split('/').last,
            ),
          ),
        );
      }

      final response = await _apiClient.dio.put(
        '/api/auth/profile',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data['user'] ?? response.data;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(
              e.response?.data['message'] ?? 'Failed to update profile',
            );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _apiClient.dio.post(
        '/api/auth/change-password',
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(
              e.response?.data['message'] ?? 'Failed to change password',
            );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
