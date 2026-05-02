import 'package:equatable/equatable.dart';

sealed class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to fetch a list of products, optionally filtered or paginated
class ProductsFetchRequested extends ProductEvent {
  final String? category;
  final String? search;
  final int page;

  const ProductsFetchRequested({this.category, this.search, this.page = 1});

  @override
  List<Object?> get props => [category, search, page];
}

/// Dispatched as the user types in the search bar (will be debounced)
class ProductsSearchChanged extends ProductEvent {
  final String query;

  const ProductsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Dispatched when the user taps a category chip
class ProductsCategorySelected extends ProductEvent {
  final String? category;

  const ProductsCategorySelected(this.category);

  @override
  List<Object?> get props => [category];
}

/// Dispatched when navigating to the Product Details screen
class ProductDetailFetchRequested extends ProductEvent {
  final String productId;

  const ProductDetailFetchRequested(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Dispatched via pull-to-refresh
class ProductsRefreshRequested extends ProductEvent {
  const ProductsRefreshRequested();
}

// Event to restore the home screen list
class RestoreListRequested extends ProductEvent {
  const RestoreListRequested();
}

/// Dispatched to fetch the list of available categories from the backend
class CategoriesFetchRequested extends ProductEvent {
  const CategoriesFetchRequested();
}
