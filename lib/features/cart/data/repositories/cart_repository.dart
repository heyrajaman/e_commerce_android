import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/cart_model.dart';
import '../../../../shared/services/storage_service.dart';

class CartRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  CartRepository({
    required ApiClient apiClient,
    required StorageService storageService,
  }) : _apiClient = apiClient,
       _storageService = storageService;

  // PROD FIX: Ensure backend validation errors (like "Out of stock") reach the UI!
  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
      final responseData = e.response!.data as Map<String, dynamic>;
      if (responseData['message'] != null) {
        return responseData['message'].toString();
      }
    }
    return e.message ?? 'An unknown network error occurred';
  }

  Future<CartModel> getCart() async {
    try {
      final userId = await _storageService.getUserId();

      if (userId == null || userId.isEmpty) {
        throw ServerException('User not authenticated');
      }

      final response = await _apiClient.dio.get(ApiEndpoints.cartGet(userId));

      // SonarQube FIX: Explicit type casting for safety
      final Map<String, dynamic> data = response.data['cart'] ?? response.data;
      return CartModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'GetCart mapping error',
        error: e,
        stackTrace: stack,
        name: 'CartRepository',
      );
      throw ServerException('Failed to process cart data.');
    }
  }

  Future<CartModel> addToCart(String productId, int quantity) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.cartAdd,
        data: {'productId': productId, 'quantity': quantity},
      );

      final Map<String, dynamic> data = response.data['cart'] ?? response.data;
      return CartModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'AddToCart mapping error',
        error: e,
        stackTrace: stack,
        name: 'CartRepository',
      );
      throw ServerException('Failed to process cart addition.');
    }
  }

  Future<CartModel> updateCartItem(String cartItemId, int quantity) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.cartUpdate(cartItemId),
        data: {'quantity': quantity},
      );

      final Map<String, dynamic> data = response.data['cart'] ?? response.data;
      return CartModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'UpdateCartItem mapping error',
        error: e,
        stackTrace: stack,
        name: 'CartRepository',
      );
      throw ServerException('Failed to update cart item.');
    }
  }

  Future<void> removeCartItem(String cartItemId) async {
    try {
      await _apiClient.dio.delete(ApiEndpoints.cartRemove(cartItemId));
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'RemoveCartItem error',
        error: e,
        stackTrace: stack,
        name: 'CartRepository',
      );
      throw ServerException('Failed to remove item from cart.');
    }
  }

  Future<void> clearCart() async {
    try {
      await _apiClient.dio.delete(ApiEndpoints.cartClear);
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'ClearCart error',
        error: e,
        stackTrace: stack,
        name: 'CartRepository',
      );
      throw ServerException('Failed to clear cart.');
    }
  }
}
