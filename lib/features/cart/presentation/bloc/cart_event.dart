import 'package:equatable/equatable.dart';

sealed class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class CartFetchRequested extends CartEvent {
  const CartFetchRequested();
}

class CartItemAdded extends CartEvent {
  final String productId;
  final int quantity;

  const CartItemAdded({
    required this.productId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, quantity];
}

class CartItemQuantityUpdated extends CartEvent {
  final String cartItemId;
  final int newQuantity;

  const CartItemQuantityUpdated({
    required this.cartItemId,
    required this.newQuantity,
  });

  @override
  List<Object?> get props => [cartItemId, newQuantity];
}

class CartItemRemoved extends CartEvent {
  final String cartItemId;

  const CartItemRemoved(this.cartItemId);

  @override
  List<Object?> get props => [cartItemId];
}

class CartCleared extends CartEvent {
  const CartCleared();
}

class CartResetLocal extends CartEvent {
  const CartResetLocal();

  @override
  List<Object> get props => [];
}