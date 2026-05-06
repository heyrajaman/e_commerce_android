import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../shared/models/cart_model.dart';
import '../../data/repositories/cart_repository.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _cartRepository;

  CartBloc({required CartRepository cartRepository})
    : _cartRepository = cartRepository,
      super(const CartInitial()) {
    on<CartFetchRequested>(_onCartFetchRequested);
    on<CartItemAdded>(_onCartItemAdded);
    on<CartItemQuantityUpdated>(_onCartItemQuantityUpdated);
    on<CartItemRemoved>(_onCartItemRemoved);
    on<CartCleared>(_onCartCleared);
    on<CartResetLocal>(_onCartResetLocal);
  }

  CartModel? _getCurrentCart() {
    if (state is CartLoaded) return (state as CartLoaded).cart;
    if (state is CartUpdating) return (state as CartUpdating).cart;
    return null;
  }

  Future<void> _onCartFetchRequested(
    CartFetchRequested event,
    Emitter<CartState> emit,
  ) async {
    final currentCart = _getCurrentCart();

    // This stops the Cart Badge from disappearing while the API fetches new data!
    if (currentCart != null) {
      emit(CartUpdating(currentCart));
    } else {
      emit(const CartLoading());
    }

    try {
      final cart = await _cartRepository.getCart();
      emit(CartLoaded(cart));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> _onCartItemAdded(
    CartItemAdded event,
    Emitter<CartState> emit,
  ) async {
    final currentCart = _getCurrentCart();

    if (currentCart != null && state is! CartLoading) {
      final updatedItems = List<CartItemModel>.from(currentCart.items);
      final existingIndex = updatedItems.indexWhere(
        (item) => item.productId == event.productId,
      );

      if (existingIndex >= 0) {
        final existingItem = updatedItems[existingIndex];
        updatedItems[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + event.quantity,
        );
      } else {
        updatedItems.add(
          CartItemModel(
            id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
            productId: event.productId,
            quantity: event.quantity,
            name: 'Adding...',
            price: 0.0,
            image: '',
            stock: 99,
            vendorId: 0,
          ),
        );
      }
      emit(CartUpdating(currentCart.copyWith(items: updatedItems)));
    }

    try {
      await _cartRepository.addToCart(event.productId, event.quantity);

      add(const CartFetchRequested());

      if (event.quantity > 0) {
        Fluttertoast.showToast(
          msg: "Item added to cart",
          backgroundColor: Colors.green.shade600,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      if (currentCart != null) {
        emit(CartLoaded(currentCart));
      } else {
        emit(CartError(e.toString()));
      }
      Fluttertoast.showToast(
        msg: e.toString(),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _onCartItemQuantityUpdated(
    CartItemQuantityUpdated event,
    Emitter<CartState> emit,
  ) async {
    final currentCart = _getCurrentCart();
    if (currentCart == null) return;

    final updatedItems = currentCart.items.map((item) {
      if (item.id == event.cartItemId) {
        return item.copyWith(quantity: event.newQuantity);
      }
      return item;
    }).toList();

    final optimisticCart = currentCart.copyWith(items: updatedItems);
    emit(CartUpdating(optimisticCart));

    try {
      await _cartRepository.updateCartItem(event.cartItemId, event.newQuantity);
      add(const CartFetchRequested());
    } catch (e) {
      emit(CartLoaded(currentCart));
      Fluttertoast.showToast(
        msg: "Failed to update quantity",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _onCartItemRemoved(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) async {
    final currentCart = _getCurrentCart();
    if (currentCart == null) return;

    final updatedItems = currentCart.items
        .where((item) => item.id != event.cartItemId)
        .toList();
    final optimisticCart = currentCart.copyWith(items: updatedItems);
    emit(CartUpdating(optimisticCart));

    try {
      await _cartRepository.removeCartItem(event.cartItemId);
      add(const CartFetchRequested());
    } catch (e) {
      emit(CartLoaded(currentCart));
      Fluttertoast.showToast(
        msg: "Failed to remove item",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _onCartCleared(
    CartCleared event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());

    try {
      await _cartRepository.clearCart();
      add(const CartFetchRequested());
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  void _onCartResetLocal(CartResetLocal event, Emitter<CartState> emit) {
    emit(const CartLoaded(CartModel(items: [])));
  }
}
