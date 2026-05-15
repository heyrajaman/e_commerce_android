import 'dart:developer' as developer; // PROD FIX: Secure logging

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/delivery_task_model.dart';

class DeliveryRepository {
  final ApiClient _apiClient;

  DeliveryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // PROD FIX: Standardized error extraction to display backend messages to the delivery partner
  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
      final responseData = e.response!.data as Map<String, dynamic>;
      if (responseData['message'] != null) {
        return responseData['message'].toString();
      }
    }
    return e.message ?? 'An unknown network error occurred';
  }

  /// Fetches the assigned active and history tasks for the logged-in delivery boy
  Future<DeliveryTasksResponse> getMyTasks() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.deliveryTasks);

      // SONARQUBE FIX: Explicit map casting
      final Map<String, dynamic> data = response.data as Map<String, dynamic>;

      return DeliveryTasksResponse.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'GetMyTasks mapping error',
        error: e,
        stackTrace: stack,
        name: 'DeliveryRepository',
      );
      throw ServerException('Failed to process delivery tasks.');
    }
  }

  /// Updates the status of a specific task (e.g., "PICKED", "DELIVERED")
  Future<void> updateTaskStatus({
    required String assignmentId,
    required String status,
    String? codPaymentMode,
    String? utrNumber,
  }) async {
    try {
      final Map<String, dynamic> bodyData = {'status': status};
      if (codPaymentMode != null) bodyData['codPaymentMode'] = codPaymentMode;
      if (utrNumber != null) bodyData['utrNumber'] = utrNumber;

      await _apiClient.dio.put(
        ApiEndpoints.updateDeliveryTaskStatus(assignmentId),
        data: bodyData,
      );
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'UpdateTaskStatus error',
        error: e,
        stackTrace: stack,
        name: 'DeliveryRepository',
      );
      throw ServerException('Failed to update task status.');
    }
  }

  Future<String> getDeliveryQRCode(String orderId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.deliveryQrCode,
        data: {'orderId': orderId},
      );

      // PROD FIX: Safely extract and cast to String
      return response.data['qrString']?.toString() ?? '';
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'GetDeliveryQRCode error',
        error: e,
        stackTrace: stack,
        name: 'DeliveryRepository',
      );
      throw ServerException('Failed to generate QR code.');
    }
  }

  /// Fetches the delivery boy profile
  Future<DeliveryBoyProfile> getDeliveryProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.deliveryProfile);

      // SONARQUBE FIX: Explicit map casting
      final Map<String, dynamic> profileData =
          response.data['profile'] as Map<String, dynamic>;
      return DeliveryBoyProfile.fromJson(profileData);
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'GetDeliveryProfile mapping error',
        error: e,
        stackTrace: stack,
        name: 'DeliveryRepository',
      );
      throw ServerException('Failed to process profile data.');
    }
  }

  /// Changes the delivery boy password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.dio.put(
        ApiEndpoints.deliveryChangePassword,
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'ChangePassword error',
        error: e,
        stackTrace: stack,
        name: 'DeliveryRepository',
      );
      throw ServerException('Failed to change password.');
    }
  }
}
