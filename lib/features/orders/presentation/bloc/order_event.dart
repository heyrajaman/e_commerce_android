import 'package:equatable/equatable.dart';

sealed class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class OrdersFetchRequested extends OrderEvent {
  const OrdersFetchRequested();
}

class OrdersLoadMoreRequested extends OrderEvent {
  const OrdersLoadMoreRequested();
}

class OrderDetailFetchRequested extends OrderEvent {
  final String orderId;

  const OrderDetailFetchRequested({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class OrderTrackRequested extends OrderEvent {
  final String orderId;

  const OrderTrackRequested({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class OrderCancelRequested extends OrderEvent {
  final String orderId;
  final String reason;

  // 🟢 PROD COMPILE FIX: Switched to named parameters
  const OrderCancelRequested({required this.orderId, required this.reason});

  @override
  List<Object?> get props => [orderId, reason];
}

class OrderItemCancelRequested extends OrderEvent {
  final String orderId;
  final String itemId;
  final String reason;

  // 🟢 PROD COMPILE FIX: Switched to named parameters
  const OrderItemCancelRequested({
    required this.orderId,
    required this.itemId,
    required this.reason,
  });

  @override
  List<Object?> get props => [orderId, itemId, reason];
}

class OrdersRefreshRequested extends OrderEvent {
  const OrdersRefreshRequested();
}

class OrderRequestReturnEvent extends OrderEvent {
  final String orderId;
  final String itemId;
  final String reason;
  final String paymentMethod;
  final String? refundMethod;
  final Map<String, dynamic>? bankDetails;

  const OrderRequestReturnEvent({
    required this.orderId,
    required this.itemId,
    required this.reason,
    required this.paymentMethod,
    this.refundMethod,
    this.bankDetails,
  });

  @override
  List<Object?> get props => [
    orderId,
    itemId,
    reason,
    paymentMethod,
    refundMethod,
    bankDetails,
  ];
}
