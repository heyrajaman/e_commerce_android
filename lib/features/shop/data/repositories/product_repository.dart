import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/product_model.dart';

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  Future<List<ProductModel>> getProducts({
    String? category,
    String? search,
    int page = 1,
  }) async {
    try {
      // Build the query parameters map dynamically
      final queryParams = <String, dynamic>{
        'page': page,
      };

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.dio.get(
        ApiEndpoints.products,
        queryParameters: queryParams,
      );

      // Handle both { "products": [...] } wrapper and direct [...] array responses
      final data = response.data['products'] ?? response.data;

      if (data is List) {
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Failed to fetch products');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.productDetails(id),
      );

      // Handle both { "product": {...} } wrapper and direct {...} object responses
      final data = response.data['product'] ?? response.data;

      return ProductModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ServerException(e.message ?? 'Failed to fetch product details');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}