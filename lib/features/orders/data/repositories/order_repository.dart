import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/order_model.dart';

class OrderRepository {
  final ApiClient _apiClient;

  OrderRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<OrderModel>> getUserOrders() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.userOrders);

      // Handle both cases: wrapped in 'orders' key or returned as a raw list
      final data = response.data['orders'] ?? response.data;

      if (data is List) {
        return data.map((json) => OrderModel.fromJson(json)).toList();
      }
      return [];
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