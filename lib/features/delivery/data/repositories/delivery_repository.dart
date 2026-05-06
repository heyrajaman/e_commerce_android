import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/delivery_task_model.dart';

class DeliveryRepository {
  final ApiClient _apiClient;

  DeliveryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches the assigned active and history tasks for the logged-in delivery boy
  Future<DeliveryTasksResponse> getMyTasks() async {
    try {
      // 1. Add .dio before .get
      final response = await _apiClient.dio.get(ApiEndpoints.deliveryTasks);

      // 2. Dio automatically decodes the JSON and places it inside response.data!
      final Map<String, dynamic> data = response.data;

      return DeliveryTasksResponse.fromJson(data);
    } catch (e) {
      throw Exception('Error fetching delivery tasks: $e');
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

      // 3. Add .dio before .put, and change 'body:' to 'data:'
      await _apiClient.dio.put(
        ApiEndpoints.updateDeliveryTaskStatus(assignmentId),
        data: bodyData,
      );
    } catch (e) {
      throw Exception('Error updating task status: $e');
    }
  }

  Future<String> getDeliveryQRCode(String orderId) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.deliveryQrCode,
      data: {'orderId': orderId},
    );
    return response.data['qrString'];
  }

  /// Fetches the delivery boy profile
  Future<DeliveryBoyProfile> getDeliveryProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.deliveryProfile);
      return DeliveryBoyProfile.fromJson(response.data['profile']);
    } catch (e) {
      throw Exception('Error fetching profile: $e');
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
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }
}
