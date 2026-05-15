import 'dart:developer' as developer; // PROD FIX: Secure logging

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/order_model.dart';

class PaginatedOrderResponse {
  final List<OrderModel> orders;
  final int currentPage;
  final int totalPages;

  PaginatedOrderResponse({
    required this.orders,
    required this.currentPage,
    required this.totalPages,
  });
}

class OrderRepository {
  final ApiClient _apiClient;

  OrderRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // PROD FIX: Standardized error extraction to display backend messages to the user
  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
      final responseData = e.response!.data as Map<String, dynamic>;
      if (responseData['message'] != null) {
        return responseData['message'].toString();
      }
    }
    return e.message ?? 'An unknown network error occurred';
  }

  Future<PaginatedOrderResponse> getUserOrders({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.userOrders,
        queryParameters: {'page': page, 'limit': limit},
      );

      final dynamic rawData = response.data;

      // SONARQUBE FIX: Explicit list casting
      final List<dynamic> dataList =
          rawData['orders'] ?? rawData['data'] ?? rawData['rows'] ?? [];

      // SONARQUBE FIX: Explicit Map casting for JSON safety
      final orders = dataList
          .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return PaginatedOrderResponse(
        orders: orders,
        currentPage: rawData['currentPage'] ?? 1,
        totalPages: rawData['totalPages'] ?? 1,
      );
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'GetUserOrders mapping error',
        error: e,
        stackTrace: stack,
        name: 'OrderRepository',
      );
      throw ServerException('Failed to process orders data.');
    }
  }

  Future<OrderModel> getOrderById(String id) async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.orderDetails(id));

      // SONARQUBE FIX: Explicit Map casting
      final Map<String, dynamic> data = response.data['order'] ?? response.data;
      return OrderModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'GetOrderById mapping error',
        error: e,
        stackTrace: stack,
        name: 'OrderRepository',
      );
      throw ServerException('Failed to process order details.');
    }
  }

  Future<void> cancelOrder(String id, String reason) async {
    try {
      await _apiClient.dio.put(
        ApiEndpoints.cancelOrder(id),
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'CancelOrder error',
        error: e,
        stackTrace: stack,
        name: 'OrderRepository',
      );
      throw ServerException('Failed to cancel order.');
    }
  }

  Future<void> cancelOrderItem(
    String orderId,
    String itemId,
    String reason,
  ) async {
    try {
      await _apiClient.dio.put(
        ApiEndpoints.cancelOrderItem(orderId, itemId),
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'CancelOrderItem error',
        error: e,
        stackTrace: stack,
        name: 'OrderRepository',
      );
      throw ServerException('Failed to cancel item.');
    }
  }

  Future<OrderModel> trackOrder(String id) async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.trackOrder(id));

      // SONARQUBE FIX: Explicit Map casting
      final Map<String, dynamic> data = response.data['order'] ?? response.data;
      return OrderModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'TrackOrder mapping error',
        error: e,
        stackTrace: stack,
        name: 'OrderRepository',
      );
      throw ServerException('Failed to process tracking data.');
    }
  }

  Future<void> requestReturn({
    required String orderId,
    required String itemId,
    required String reason,
    required String paymentMethod,
    String? refundMethod,
    Map<String, dynamic>? bankDetails,
  }) async {
    try {
      final Map<String, dynamic> payload = {'reason': reason};

      if (paymentMethod == 'COD') {
        payload['refundMethod'] = refundMethod ?? 'WAREHOUSE_COLLECT';
        if (refundMethod == 'BANK_TRANSFER' && bankDetails != null) {
          payload['bankDetails'] = bankDetails;
        }
      } else {
        payload['refundMethod'] = 'ORIGINAL_SOURCE';
      }

      await _apiClient.dio.post(
        ApiEndpoints.requestReturnItem(orderId, itemId),
        data: payload,
      );
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'RequestReturn error',
        error: e,
        stackTrace: stack,
        name: 'OrderRepository',
      );
      throw ServerException('Failed to submit return request.');
    }
  }
}
