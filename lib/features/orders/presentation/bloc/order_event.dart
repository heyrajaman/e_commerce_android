import 'package:equatable/equatable.dart';

sealed class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class OrdersFetchRequested extends OrderEvent {
  const OrdersFetchRequested();
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

  const OrderCancelRequested(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class OrdersRefreshRequested extends OrderEvent {
  const OrdersRefreshRequested();
}