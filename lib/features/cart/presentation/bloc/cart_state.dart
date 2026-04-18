import 'package:equatable/equatable.dart';

import '../../../../shared/models/cart_model.dart';

sealed class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {
  const CartInitial();
}

class CartLoading extends CartState {
  const CartLoading();
}

class CartLoaded extends CartState {
  final CartModel cart;

  const CartLoaded(this.cart);

  // Convenient getters to access totals directly from the state
  int get totalItems => cart.totalItems;
  double get subtotal => cart.subtotal;

  @override
  List<Object?> get props => [cart];
}

/// State used for optimistic UI updates.
/// It holds the current cart data so the UI doesn't disappear,
/// while indicating that a background network request is happening.
class CartUpdating extends CartState {
  final CartModel cart;

  const CartUpdating(this.cart);

  // Convenient getters to access totals directly from the state
  int get totalItems => cart.totalItems;
  double get subtotal => cart.subtotal;

  @override
  List<Object?> get props => [cart];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}