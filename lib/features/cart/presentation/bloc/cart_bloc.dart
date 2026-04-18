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
  }

  // Helper to extract the current cart safely from the state
  CartModel? _getCurrentCart() {
    if (state is CartLoaded) return (state as CartLoaded).cart;
    if (state is CartUpdating) return (state as CartUpdating).cart;
    return null;
  }

  Future<void> _onCartFetchRequested(
      CartFetchRequested event,
      Emitter<CartState> emit,
      ) async {
    emit(const CartLoading());
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

    // Show updating state so the user doesn't lose their current view
    if (currentCart != null) {
      emit(CartUpdating(currentCart));
    } else {
      emit(const CartLoading());
    }

    try {
      final updatedCart = await _cartRepository.addToCart(event.productId, event.quantity);
      emit(CartLoaded(updatedCart));
      Fluttertoast.showToast(
        msg: "Item added to cart",
        backgroundColor: Colors.green.shade600,
        textColor: Colors.white,
      );
    } catch (e) {
      // Revert to old cart if it fails
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

    // 1. Optimistic Update: Instantly modify the local cart to feel fast
    final updatedItems = currentCart.items.map((item) {
      if (item.id == event.cartItemId) {
        return item.copyWith(quantity: event.newQuantity);
      }
      return item;
    }).toList();

    final optimisticCart = currentCart.copyWith(items: updatedItems);
    emit(CartUpdating(optimisticCart));

    // 2. Sync with Backend
    try {
      final apiCart = await _cartRepository.updateCartItem(event.cartItemId, event.newQuantity);
      emit(CartLoaded(apiCart));
    } catch (e) {
      // Revert if API fails
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

    // 1. Optimistic Update: Instantly remove item locally
    final updatedItems = currentCart.items.where((item) => item.id != event.cartItemId).toList();
    final optimisticCart = currentCart.copyWith(items: updatedItems);
    emit(CartUpdating(optimisticCart));

    // 2. Sync with Backend
    try {
      await _cartRepository.removeCartItem(event.cartItemId);
      // Trust our optimistic cart since the remove API might just return 200 OK without data
      emit(CartLoaded(optimisticCart));
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
    final currentCart = _getCurrentCart();
    if (currentCart != null) emit(CartUpdating(currentCart));

    try {
      await _cartRepository.clearCart();
      // Emit an empty cart on success
      emit(const CartLoaded(CartModel(items: [])));
    } catch (e) {
      if (currentCart != null) emit(CartLoaded(currentCart));
      Fluttertoast.showToast(
        msg: "Failed to clear cart",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}