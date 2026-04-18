import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/order_repository.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _orderRepository;

  OrderBloc({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const OrderInitial()) {
    on<OrdersFetchRequested>(_onOrdersFetchRequested);
    on<OrderDetailFetchRequested>(_onOrderDetailFetchRequested);
    on<OrderTrackRequested>(_onOrderTrackRequested);
    on<OrderCancelRequested>(_onOrderCancelRequested);
    on<OrdersRefreshRequested>(_onOrdersRefreshRequested);
  }

  Future<void> _onOrdersFetchRequested(
      OrdersFetchRequested event,
      Emitter<OrderState> emit,
      ) async {
    emit(const OrdersLoading());
    try {
      final orders = await _orderRepository.getUserOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onOrderDetailFetchRequested(
      OrderDetailFetchRequested event,
      Emitter<OrderState> emit,
      ) async {
    emit(const OrderDetailLoading());
    try {
      final order = await _orderRepository.getOrderById(event.orderId);
      emit(OrderDetailLoaded(order));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onOrderTrackRequested(
      OrderTrackRequested event,
      Emitter<OrderState> emit,
      ) async {
    emit(const OrderDetailLoading());
    try {
      // Assuming trackOrder returns the updated OrderModel with tracking info
      final order = await _orderRepository.trackOrder(event.orderId);
      emit(OrderDetailLoaded(order));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onOrderCancelRequested(
      OrderCancelRequested event,
      Emitter<OrderState> emit,
      ) async {
    emit(const OrderCancelling());
    try {
      await _orderRepository.cancelOrder(event.orderId);
      emit(OrderCancelled(event.orderId));

      // Automatically refresh the orders list to reflect the cancelled status
      add(const OrdersFetchRequested());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onOrdersRefreshRequested(
      OrdersRefreshRequested event,
      Emitter<OrderState> emit,
      ) async {
    // We don't emit OrdersLoading here so the UI can keep showing the current
    // list (or a pull-to-refresh indicator) while the background fetch happens.
    try {
      final orders = await _orderRepository.getUserOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }
}