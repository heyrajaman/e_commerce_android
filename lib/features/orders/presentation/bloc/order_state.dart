import 'package:equatable/equatable.dart';

import '../../../../shared/models/order_model.dart';

sealed class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrdersLoading extends OrderState {
  const OrdersLoading();
}

// 🟢 UPDATED: Now tracks current page and if we hit the end of the list
class OrdersLoaded extends OrderState {
  final List<OrderModel> orders;
  final bool hasReachedMax;
  final int currentPage;

  const OrdersLoaded({
    required this.orders,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  // Helper to append new orders to the existing list
  OrdersLoaded copyWith({
    List<OrderModel>? orders,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [orders, hasReachedMax, currentPage];
}

class OrderDetailLoading extends OrderState {
  const OrderDetailLoading();
}

class OrderDetailLoaded extends OrderState {
  final OrderModel order;

  const OrderDetailLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderCancelling extends OrderState {
  const OrderCancelling();
}

class OrderCancelled extends OrderState {
  final String orderId;

  const OrderCancelled(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}
