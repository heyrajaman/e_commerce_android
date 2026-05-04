import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/models/order_model.dart';
import '../../../shop/data/repositories/product_repository.dart';
import '../../data/repositories/order_repository.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _orderRepository;
  final ProductRepository _productRepository;

  // Track if a load more request is currently running so we don't spam the API
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
    // 🟢 FIX 3: Register the event handler here!
    on<OrderItemCancelRequested>(_onOrderItemCancelRequested);
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
    } catch (e) {
      // Silently fail
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
            ),
          );
        } catch (e) {
          enrichedItems.add(item);
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
      await _orderRepository.cancelOrder(event.orderId, event.reason);
      emit(OrderCancelled(event.orderId));
      add(const OrdersFetchRequested());
    } catch (e) {
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
      add(OrderDetailFetchRequested(event.orderId));
    } catch (e) {
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
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }
}
