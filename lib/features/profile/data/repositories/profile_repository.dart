import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/address_model.dart';
import '../../../../shared/models/user_model.dart';

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null && e.response?.data is Map) {
      final responseData = e.response!.data as Map;
      if (responseData['message'] != null) {
        return responseData['message'].toString();
      }
    }
    return e.message ?? 'An unknown error occurred';
  }

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

  Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await _apiClient.dio.get('/api/addresses');
      return (response.data as List)
          .map((json) => AddressModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<AddressModel> addAddress(
    String addressLine1,
    String state,
    String city,
    String area,
    bool isDefault,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/addresses',
        data: {
          'addressLine1': addressLine1,
          'state': state,
          'city': city,
          'area': area,
          'isDefault': isDefault,
        },
      );
      return AddressModel.fromJson(response.data['address']);
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _apiClient.dio.delete('/api/addresses/$id');
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
