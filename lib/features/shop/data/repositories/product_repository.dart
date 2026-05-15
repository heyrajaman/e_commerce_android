import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/product_model.dart';

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
      final responseData = e.response!.data as Map<String, dynamic>;
      if (responseData['message'] != null) {
        return responseData['message'].toString();
      }
    }
    return e.message ?? 'An unknown network error occurred';
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/api/products/categories');

      List<String> categories = ['All'];

      if (response.data is List) {
        if (response.data.isNotEmpty && response.data is String) {
          categories.addAll(List<String>.from(response.data));
        } else {
          final fetchedCategories = (response.data as List)
              .map((category) => category['name'] as String)
              .toList();
          categories.addAll(fetchedCategories);
        }
      }

      return categories;
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      // SONARQUBE FIX: Consistent exception type and secure logging
      developer.log(
        'GetCategories error',
        error: e,
        stackTrace: stack,
        name: 'ProductRepository',
      );
      throw ServerException('Failed to load categories.');
    }
  }

  Future<List<ProductModel>> getProducts({
    String? category,
    String? search,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};

      if (category != null && category.isNotEmpty && category != 'All') {
        queryParams['category'] = category;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.dio.get(
        ApiEndpoints.products,
        queryParameters: queryParams,
      );

      // Robust extraction for paginated wrappers
      final dynamic rawData = response.data;
      final data = rawData is Map
          ? (rawData['rows'] ?? rawData['products'] ?? rawData)
          : rawData;

      if (data is List) {
        // Explicit cast to prevent dynamic type crashing
        return data
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'GetProducts mapping error',
        error: e,
        stackTrace: stack,
        name: 'ProductRepository',
      );
      throw ServerException('Failed to process products data.');
    }
  }

  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.productDetails(id),
      );

      final Map<String, dynamic> data =
          response.data['product'] ?? response.data;
      return ProductModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_extractErrorMessage(e));
    } catch (e, stack) {
      developer.log(
        'GetProductById mapping error',
        error: e,
        stackTrace: stack,
        name: 'ProductRepository',
      );
      throw ServerException('Failed to process product details.');
    }
  }
}
