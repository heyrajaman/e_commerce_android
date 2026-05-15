import 'dart:developer' as developer; // PROD FIX: Secure logging

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/models/order_model.dart';
import '../../../shop/data/repositories/product_repository.dart';
import '../../data/repositories/order_repository.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _orderRepository;
  final ProductRepository _productRepository;

  bool _isFetchingMore = false;

  OrderBloc({
    required OrderRepository orderRepository,
    required ProductRepository productRepository,
  }) : _orderRepository = orderRepository,
       _productRepository = productRepository,
       super(const OrderInitial()) {
    on<OrdersFetchRequested>(_onOrdersFetchRequested);
    on<OrdersLoadMoreRequested>(_onOrdersLoadMoreRequested);
    on<OrderDetailFetchRequested>(_onOrderDetailFetchRequested);
    on<OrderTrackRequested>(_onOrderTrackRequested);
    on<OrderCancelRequested>(_onOrderCancelRequested);
    on<OrderItemCancelRequested>(_onOrderItemCancelRequested);
    on<OrdersRefreshRequested>(_onOrdersRefreshRequested);
    on<OrderRequestReturnEvent>(_onOrderRequestReturnEvent);
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
    } catch (e, stack) {
      developer.log(
        'Orders fetch failed',
        error: e,
        stackTrace: stack,
        name: 'OrderBloc',
      );
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onOrdersLoadMoreRequested(
    OrdersLoadMoreRequested event,
    Emitter<OrderState> emit,
  ) async {
    if (state is! OrdersLoaded || _isFetchingMore) return;

    final currentState = state as OrdersLoaded;
    if (currentState.hasReachedMax) return;

    _isFetchingMore = true;
    try {
      final nextPage = currentState.currentPage + 1;
      final response = await _orderRepository.getUserOrders(page: nextPage);

      emit(
        currentState.copyWith(
          orders: List.of(currentState.orders)..addAll(response.orders),
          currentPage: response.currentPage,
          hasReachedMax: response.currentPage >= response.totalPages,
        ),
      );
    } catch (e, stack) {
      // PROD LOGGING FIX: Do not silently swallow errors. Log them securely while failing gracefully in UI.
      developer.log(
        'Load more orders failed',
        error: e,
        stackTrace: stack,
        name: 'OrderBloc',
      );
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
      final rawOrder = await _orderRepository.getOrderById(event.orderId);

      List<OrderItemModel> enrichedItems = [];
      for (var item in rawOrder.items) {
        try {
          final productDetails = await _productRepository.getProductById(
            item.productId,
          );

          enrichedItems.add(
            OrderItemModel(
              itemId: item.itemId,
              productId: item.productId,
              name: productDetails.name,
              image: productDetails.images.isNotEmpty
                  ? productDetails.images.first
                  : '',
              price: item.price,
              quantity: item.quantity,
              status: item.status,
              refundStatus: item.refundStatus,
            ),
          );
        } catch (e, stack) {
          developer.log(
            'Failed to enrich order item ${item.itemId}',
            error: e,
            stackTrace: stack,
            name: 'OrderBloc',
          );
          enrichedItems.add(item); // Fallback to raw item if enrichment fails
        }
      }

      final enrichedOrder = OrderModel(
        id: rawOrder.id,
        items: enrichedItems,
        shippingAddress: rawOrder.shippingAddress,
        paymentMethod: rawOrder.paymentMethod,
        totalAmount: rawOrder.totalAmount,
        shippingCharge: rawOrder.shippingCharge,
        status: rawOrder.status,
        createdAt: rawOrder.createdAt,
        trackingInfo: rawOrder.trackingInfo,
      );

      emit(OrderDetailLoaded(enrichedOrder));
    } catch (e, stack) {
      developer.log(
        'Order detail fetch failed',
        error: e,
        stackTrace: stack,
        name: 'OrderBloc',
      );
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
    } catch (e, stack) {
      developer.log(
        'Order track fetch failed',
        error: e,
        stackTrace: stack,
        name: 'OrderBloc',
      );
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onOrderCancelRequested(
    OrderCancelRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderCancelling());
    try {
      await _orderRepository.cancelOrder(event.orderId, event.reason);
      emit(OrderCancelled(event.orderId));
      add(const OrdersFetchRequested());
    } catch (e, stack) {
      developer.log(
        'Order cancel failed',
        error: e,
        stackTrace: stack,
        name: 'OrderBloc',
      );
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onOrderItemCancelRequested(
    OrderItemCancelRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderCancelling());
    try {
      await _orderRepository.cancelOrderItem(
        event.orderId,
        event.itemId,
        event.reason,
      );
      // PROD COMPILE FIX: Use named parameters
      add(OrderDetailFetchRequested(orderId: event.orderId));
    } catch (e, stack) {
      developer.log(
        'Order item cancel failed',
        error: e,
        stackTrace: stack,
        name: 'OrderBloc',
      );
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onOrdersRefreshRequested(
    OrdersRefreshRequested event,
    Emitter<OrderState> emit,
  ) async {
    try {
      final response = await _orderRepository.getUserOrders(page: 1);
      emit(
        OrdersLoaded(
          orders: response.orders,
          currentPage: response.currentPage,
          hasReachedMax: response.currentPage >= response.totalPages,
        ),
      );
    } catch (e, stack) {
      developer.log(
        'Orders refresh failed',
        error: e,
        stackTrace: stack,
        name: 'OrderBloc',
      );
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onOrderRequestReturnEvent(
    OrderRequestReturnEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderReturnRequestLoading());
    try {
      await _orderRepository.requestReturn(
        orderId: event.orderId,
        itemId: event.itemId,
        reason: event.reason,
        paymentMethod: event.paymentMethod,
        refundMethod: event.refundMethod,
        bankDetails: event.bankDetails,
      );

      emit(
        const OrderReturnRequestSuccess(
          'Return requested successfully. Refund will be processed after Admin verification.',
        ),
      );

      // PROD COMPILE FIX: Use named parameters
      add(OrderDetailFetchRequested(orderId: event.orderId));
    } catch (e, stack) {
      developer.log(
        'Order return request failed',
        error: e,
        stackTrace: stack,
        name: 'OrderBloc',
      );
      emit(OrderReturnRequestFailure(e.toString()));
    }
  }
}
