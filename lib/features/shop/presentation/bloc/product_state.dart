import 'package:equatable/equatable.dart';

import '../../../../shared/models/product_model.dart';

sealed class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any products are fetched
class ProductInitial extends ProductState {
  const ProductInitial();
}

/// Loading state for fetching lists of products
class ProductsLoading extends ProductState {
  const ProductsLoading();
}

/// State when a list of products has been successfully fetched.
/// It retains the current filter criteria and pagination status.
class ProductsLoaded extends ProductState {
  final List<ProductModel> products;
  final String? activeCategory;
  final String? searchQuery;
  final bool hasMore;

  const ProductsLoaded(
      this.products, {
        this.activeCategory,
        this.searchQuery,
        this.hasMore = true,
      });

  @override
  List<Object?> get props => [products, activeCategory, searchQuery, hasMore];
}

/// Loading state specifically for fetching a single product's details
class ProductDetailLoading extends ProductState {
  const ProductDetailLoading();
}

/// State when a single product is successfully loaded for the details screen
class ProductDetailLoaded extends ProductState {
  final ProductModel product;

  const ProductDetailLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

/// Error state for any product-related API failures
class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}