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

  Future<CartModel> getCart() async {
    try {
      // Fetch user ID securely from local storage
      final userId = await _storageService.getUserId();

      if (userId == null || userId.isEmpty) {
        // Removed the 'const' keyword here
        throw ServerException('User not authenticated');
      }

      final response = await _apiClient.dio.get(ApiEndpoints.cartGet(userId));

      final data = response.data['cart'] ?? response.data;
      return CartModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Failed to fetch cart');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<CartModel> addToCart(String productId, int quantity) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.cartAdd, // Fixed to match your ApiEndpoints
        data: {'productId': productId, 'quantity': quantity},
      );

      final data = response.data['cart'] ?? response.data;
      return CartModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Failed to add item to cart');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<CartModel> updateCartItem(String cartItemId, int quantity) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.cartUpdate(cartItemId), // Fixed to match your ApiEndpoints
        data: {'quantity': quantity},
      );

      final data = response.data['cart'] ?? response.data;
      return CartModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Failed to update cart item');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> removeCartItem(String cartItemId) async {
    try {
      await _apiClient.dio.delete(
        ApiEndpoints.cartRemove(cartItemId), // Fixed to match your ApiEndpoints
      );
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Failed to remove cart item');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> clearCart() async {
    try {
      await _apiClient.dio.delete(
        ApiEndpoints.cartClear, // Fixed to match your ApiEndpoints
      );
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Failed to clear cart');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
