import 'dart:developer' as developer; // PROD FIX: Secure logging

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/repositories/product_repository.dart';
import 'product_event.dart';
import 'product_state.dart';

/// Custom EventTransformer to debounce search inputs by a given duration
EventTransformer<Event> debounceTransformer<Event>(Duration duration) {
  return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
}

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _productRepository;

  ProductsLoaded? _lastLoadedList;

  ProductBloc({required ProductRepository productRepository})
    : _productRepository = productRepository,
      super(const ProductInitial()) {
    on<ProductsFetchRequested>(_onProductsFetchRequested);
    on<ProductsSearchChanged>(
      _onProductsSearchChanged,
      transformer: debounceTransformer(const Duration(milliseconds: 300)),
    );
    on<ProductsCategorySelected>(_onProductsCategorySelected);
    on<ProductDetailFetchRequested>(_onProductDetailFetchRequested);
    on<ProductsRefreshRequested>(_onProductsRefreshRequested);
    on<RestoreListRequested>(_onRestoreListRequested);
    on<CategoriesFetchRequested>(_onCategoriesFetchRequested);
  }

  Future<void> _onCategoriesFetchRequested(
    CategoriesFetchRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final categories = await _productRepository.getCategories();

      if (state is ProductsLoaded) {
        final currentState = state as ProductsLoaded;
        final newState = currentState.copyWith(categories: categories);
        _lastLoadedList = newState;
        emit(newState);
      } else {
        _lastLoadedList = ProductsLoaded(const [], categories: categories);
      }
    } catch (e, stack) {
      // SONARQUBE FIX: Replaced 'print' with secure logging
      developer.log(
        'Categories fetch failed, defaulting to [All]',
        error: e,
        stackTrace: stack,
        name: 'ProductBloc',
      );
    }
  }

  Future<void> _onProductsFetchRequested(
    ProductsFetchRequested event,
    Emitter<ProductState> emit,
  ) async {
    if (event.page == 1) {
      emit(const ProductsLoading());
    }

    try {
      final newProducts = await _productRepository.getProducts(
        category: event.category,
        search: event.search,
        page: event.page,
      );

      List<String> existingCategories = const ['All'];
      if (state is ProductsLoaded) {
        existingCategories = (state as ProductsLoaded).categories;
      } else if (_lastLoadedList != null) {
        existingCategories = _lastLoadedList!.categories;
      }

      ProductsLoaded newState;

      if (state is ProductsLoaded && event.page > 1) {
        final currentState = state as ProductsLoaded;
        final combinedProducts = List.of(currentState.products)
          ..addAll(newProducts);

        newState = currentState.copyWith(
          products: combinedProducts,
          activeCategory: event.category,
          searchQuery: event.search,
          hasMore: newProducts.isNotEmpty,
        );
      } else {
        newState = ProductsLoaded(
          newProducts,
          categories: existingCategories,
          activeCategory: event.category,
          searchQuery: event.search,
          hasMore: newProducts.isNotEmpty,
        );
      }

      _lastLoadedList = newState;
      emit(newState);
    } catch (e, stack) {
      // PROD FIX: Added stack traces for debugging missing products
      developer.log(
        'Products fetch failed',
        error: e,
        stackTrace: stack,
        name: 'ProductBloc',
      );
      emit(ProductError(e.toString()));
    }
  }

  void _onProductsSearchChanged(
    ProductsSearchChanged event,
    Emitter<ProductState> emit,
  ) {
    String? currentCategory;
    if (state is ProductsLoaded) {
      currentCategory = (state as ProductsLoaded).activeCategory;
    }
    add(
      ProductsFetchRequested(
        search: event.query,
        category: currentCategory,
        page: 1,
      ),
    );
  }

  void _onProductsCategorySelected(
    ProductsCategorySelected event,
    Emitter<ProductState> emit,
  ) {
    String? currentSearch;
    if (state is ProductsLoaded) {
      currentSearch = (state as ProductsLoaded).searchQuery;
    }
    add(
      ProductsFetchRequested(
        category: event.category,
        search: currentSearch,
        page: 1,
      ),
    );
  }

  Future<void> _onProductDetailFetchRequested(
    ProductDetailFetchRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductDetailLoading());
    try {
      final product = await _productRepository.getProductById(event.productId);
      emit(ProductDetailLoaded(product));
    } catch (e, stack) {
      // PROD FIX: Added stack traces for debugging detail mapping errors
      developer.log(
        'Product detail fetch failed',
        error: e,
        stackTrace: stack,
        name: 'ProductBloc',
      );
      emit(ProductError(e.toString()));
    }
  }

  void _onProductsRefreshRequested(
    ProductsRefreshRequested event,
    Emitter<ProductState> emit,
  ) {
    add(const CategoriesFetchRequested());

    String? currentCategory;
    String? currentSearch;
    if (state is ProductsLoaded) {
      final currentState = state as ProductsLoaded;
      currentCategory = currentState.activeCategory;
      currentSearch = currentState.searchQuery;
    }
    add(
      ProductsFetchRequested(
        category: currentCategory,
        search: currentSearch,
        page: 1,
      ),
    );
  }

  void _onRestoreListRequested(
    RestoreListRequested event,
    Emitter<ProductState> emit,
  ) {
    if (_lastLoadedList != null) {
      emit(_lastLoadedList!);
    }
  }
}
