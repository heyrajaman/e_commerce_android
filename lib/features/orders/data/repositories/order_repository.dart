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

  Future<PaginatedOrderResponse> getUserOrders({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.userOrders,
        queryParameters: {
          'page': page,
          'limit': limit,
        }, // Send pagination data to backend
      );

      final dynamic rawData = response.data;
      final List<dynamic> dataList =
          rawData['orders'] ?? rawData['data'] ?? rawData['rows'] ?? [];

      final orders = dataList.map((json) => OrderModel.fromJson(json)).toList();

      return PaginatedOrderResponse(
        orders: orders,
        currentPage: rawData['currentPage'] ?? 1,
        totalPages: rawData['totalPages'] ?? 1,
      );
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Failed to fetch orders');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<OrderModel> getOrderById(String id) async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.orderDetails(id));
      final data = response.data['order'] ?? response.data;
      return OrderModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Failed to fetch order details');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> cancelOrder(String id) async {
    try {
      await _apiClient.dio.put(ApiEndpoints.cancelOrder(id));
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Failed to cancel order');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<OrderModel> trackOrder(String id) async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.trackOrder(id));
      final data = response.data['order'] ?? response.data;
      return OrderModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Failed to track order');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
