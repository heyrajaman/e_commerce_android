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

    // NEW: Listen for the category fetch event
    on<CategoriesFetchRequested>(_onCategoriesFetchRequested);
  }

  // NEW: Handler for fetching categories
  Future<void> _onCategoriesFetchRequested(
    CategoriesFetchRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final categories = await _productRepository.getCategories();

      // If products are already loaded, we just inject the new categories into the state
      if (state is ProductsLoaded) {
        final currentState = state as ProductsLoaded;
        final newState = currentState.copyWith(categories: categories);
        _lastLoadedList = newState;
        emit(newState);
      } else {
        // If products haven't loaded yet, save categories to our backup
        // so the product fetcher can grab them in a second
        _lastLoadedList = ProductsLoaded(const [], categories: categories);
      }
    } catch (e) {
      // If categories fail to load, we silently fail and it defaults to ['All']
      print('Categories fetch failed: $e');
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

      // CRUCIAL: Preserve existing categories so they don't get erased!
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

        // Using our new copyWith method!
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
          // Inject the preserved categories here
          activeCategory: event.category,
          searchQuery: event.search,
          hasMore: newProducts.isNotEmpty,
        );
      }

      _lastLoadedList = newState;
      emit(newState);
    } catch (e) {
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
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  void _onProductsRefreshRequested(
    ProductsRefreshRequested event,
    Emitter<ProductState> emit,
  ) {
    // When refreshing, we also want to refresh the categories!
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
