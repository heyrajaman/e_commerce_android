import 'package:equatable/equatable.dart';

sealed class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class OrdersFetchRequested extends OrderEvent {
  const OrdersFetchRequested();
}

// 🟢 NEW: Event to trigger loading the next page
class OrdersLoadMoreRequested extends OrderEvent {
  const OrdersLoadMoreRequested();
}

class OrderDetailFetchRequested extends OrderEvent {
  final String orderId;

  const OrderDetailFetchRequested(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class OrderTrackRequested extends OrderEvent {
  final String orderId;

  const OrderTrackRequested(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class OrderCancelRequested extends OrderEvent {
  final String orderId;
  final String reason;

  const OrderCancelRequested(this.orderId, this.reason);

  @override
  List<Object?> get props => [orderId, reason];
}

class OrderItemCancelRequested extends OrderEvent {
  final String orderId;
  final String itemId;
  final String reason;

  const OrderItemCancelRequested(this.orderId, this.itemId, this.reason);

  @override
  List<Object> get props => [orderId, itemId, reason];
}

class OrdersRefreshRequested extends OrderEvent {
  const OrdersRefreshRequested();
}
