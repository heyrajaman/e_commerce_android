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

      ProductsLoaded newState;

      if (state is ProductsLoaded && event.page > 1) {
        final currentState = state as ProductsLoaded;
        final combinedProducts = List.of(currentState.products)
          ..addAll(newProducts);

        newState = ProductsLoaded(
          combinedProducts,
          activeCategory: event.category,
          searchQuery: event.search,
          hasMore: newProducts.isNotEmpty,
        );
      } else {
        newState = ProductsLoaded(
          newProducts,
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
    if (state is ProductsLoaded)
      currentCategory = (state as ProductsLoaded).activeCategory;
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
    if (state is ProductsLoaded)
      currentSearch = (state as ProductsLoaded).searchQuery;
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
