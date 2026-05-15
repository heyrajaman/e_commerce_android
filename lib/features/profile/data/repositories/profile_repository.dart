import 'dart:developer' as developer; // PROD FIX: Secure logging
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
    if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
      final responseData = e.response!.data as Map<String, dynamic>;
      if (responseData['message'] != null) {
        return responseData['message'].toString();
      }
    }
    return e.message ?? 'An unknown network error occurred';
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/api/auth/me');

      // SONARQUBE FIX: Explicit type casting
      final Map<String, dynamic> data = response.data['user'] ?? response.data;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      // PROD UX FIX: Consistent error extraction
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'GetProfile mapping error',
        error: e,
        stackTrace: stack,
        name: 'ProfileRepository',
      );
      throw ServerException('Failed to process profile data.');
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

      final Map<String, dynamic> data = response.data['user'] ?? response.data;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'UpdateProfile mapping error',
        error: e,
        stackTrace: stack,
        name: 'ProfileRepository',
      );
      throw ServerException('Failed to update profile.');
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _apiClient.dio.post(
        '/api/auth/change-password',
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'ChangePassword error',
        error: e,
        stackTrace: stack,
        name: 'ProfileRepository',
      );
      throw ServerException('Failed to change password.');
    }
  }

  Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await _apiClient.dio.get('/api/addresses');

      // SONARQUBE FIX: Safe list mapping
      final List<dynamic> dataList = response.data as List<dynamic>;
      return dataList
          .map((json) => AddressModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'GetAddresses mapping error',
        error: e,
        stackTrace: stack,
        name: 'ProfileRepository',
      );
      throw ServerException('Failed to load addresses.');
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

      final Map<String, dynamic> data = response.data['address'];
      return AddressModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'AddAddress mapping error',
        error: e,
        stackTrace: stack,
        name: 'ProfileRepository',
      );
      throw ServerException('Failed to add address.');
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _apiClient.dio.delete('/api/addresses/$id');
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'DeleteAddress error',
        error: e,
        stackTrace: stack,
        name: 'ProfileRepository',
      );
      throw ServerException('Failed to delete address.');
    }
  }
}
