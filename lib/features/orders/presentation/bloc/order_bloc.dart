import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/order_repository.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _orderRepository;

  // Track if a load more request is currently running so we don't spam the API
  bool _isFetchingMore = false;

  OrderBloc({required OrderRepository orderRepository})
    : _orderRepository = orderRepository,
      super(const OrderInitial()) {
    on<OrdersFetchRequested>(_onOrdersFetchRequested);
    on<OrdersLoadMoreRequested>(
      _onOrdersLoadMoreRequested,
    ); // 🟢 Register new event
    on<OrderDetailFetchRequested>(_onOrderDetailFetchRequested);
    on<OrderTrackRequested>(_onOrderTrackRequested);
    on<OrderCancelRequested>(_onOrderCancelRequested);
    on<OrdersRefreshRequested>(_onOrdersRefreshRequested);
  }

  Future<void> _onOrdersFetchRequested(
    OrdersFetchRequested event,
    Emitter<OrderState> emit,
  ) async {
    if (state is! OrdersLoaded) {
      emit(const OrdersLoading());
    }

    try {
      final response = await _orderRepository.getUserOrders(page: 1);
      emit(
        OrdersLoaded(
          orders: response.orders,
          currentPage: response.currentPage,
          hasReachedMax: response.currentPage >= response.totalPages,
        ),
      );
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  // 🟢 NEW: Logic for infinite scrolling
  Future<void> _onOrdersLoadMoreRequested(
    OrdersLoadMoreRequested event,
    Emitter<OrderState> emit,
  ) async {
    if (state is! OrdersLoaded || _isFetchingMore) return;

    final currentState = state as OrdersLoaded;
    if (currentState.hasReachedMax) return; // Don't fetch if we have all orders

    _isFetchingMore = true;
    try {
      final nextPage = currentState.currentPage + 1;
      final response = await _orderRepository.getUserOrders(page: nextPage);

      // Append the new orders to the existing list
      emit(
        currentState.copyWith(
          orders: List.of(currentState.orders)..addAll(response.orders),
          currentPage: response.currentPage,
          hasReachedMax: response.currentPage >= response.totalPages,
        ),
      );
    } catch (e) {
      // Silently fail or handle error (we don't want to wipe the current list on a pagination error)
    } finally {
      _isFetchingMore = false;
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
      add(const OrdersFetchRequested());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onOrdersRefreshRequested(
    OrdersRefreshRequested event,
    Emitter<OrderState> emit,
  ) async {
    try {
      // 🟢 Refresh always pulls page 1
      final response = await _orderRepository.getUserOrders(page: 1);
      emit(
        OrdersLoaded(
          orders: response.orders,
          currentPage: response.currentPage,
          hasReachedMax: response.currentPage >= response.totalPages,
        ),
      );
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }
}
