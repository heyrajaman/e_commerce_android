import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_extensions.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/mesh_gradient_background.dart';
import '../../../../shared/widgets/order_status_badge_widget.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(OrderDetailFetchRequested(widget.orderId));
  }

  // 🟢 Handle Full Order Cancellation (For 1-item orders)
  void _confirmCancelOrder(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.kGlassWhite,
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please tell us why you are cancelling this order:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for cancellation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Order', style: AppTextStyles.kBodyMedium),
          ),
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(ctx);
              context.read<OrderBloc>().add(
                OrderCancelRequested(widget.orderId, reason),
              );
            },
            child: Text(
              'Confirm Cancel',
              style: AppTextStyles.kBodyMedium.copyWith(
                color: AppColors.kError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 Handle Single Item Cancellation (For multi-item orders)
  void _confirmCancelItem(
    BuildContext context,
    String itemId,
    String itemName,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.kGlassWhite,
        title: Text('Cancel $itemName?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancelling this item:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for cancellation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Item', style: AppTextStyles.kBodyMedium),
          ),
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(ctx);
              context.read<OrderBloc>().add(
                OrderItemCancelRequested(widget.orderId, itemId, reason),
              );
            },
            child: Text(
              'Confirm Cancel',
              style: AppTextStyles.kBodyMedium.copyWith(
                color: AppColors.kError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getOrderProgress(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 1;
      case OrderStatus.confirmed:
        return 2;
      case OrderStatus.shipped:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
      case OrderStatus.returned:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 Wrap the entire screen in PopScope to detect back navigation
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          context.read<OrderBloc>().add(const OrdersFetchRequested());
        }
      },
      child: MeshGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: BlocConsumer<OrderBloc, OrderState>(
            listener: (context, state) {
              if (state is OrderCancelled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cancellation successful'),
                    backgroundColor: AppColors.kError,
                  ),
                );
                context.read<OrderBloc>().add(
                  OrderDetailFetchRequested(widget.orderId),
                );
              } else if (state is OrderError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.kError,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is OrderInitial || state is OrderDetailLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.kAccentIndigo,
                  ),
                );
              }

              if (state is OrderCancelling || state is OrderCancelled) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.kError),
                );
              }

              OrderModel? order;
              if (state is OrderDetailLoaded) {
                order = state.order;
              } else {
                final blocState = context.read<OrderBloc>().state;
                if (blocState is OrderDetailLoaded) {
                  order = blocState.order;
                }
              }

              if (order == null) {
                return Center(
                  child: Text(
                    'Order not found',
                    style: AppTextStyles.kBodyMedium,
                  ),
                );
              }

              final formattedDate = DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(order.createdAt);
              final progress = _getOrderProgress(order.status);
              final shortId = order.id.length > 8
                  ? order.id.substring(order.id.length - 8).toUpperCase()
                  : order.id.toUpperCase();

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    pinned: true,
                    title: Text(
                      'Order Details',
                      style: AppTextStyles.kHeading2,
                    ),
                    centerTitle: true,
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.kTextPrimary,
                      ),
                      onPressed: () {
                        // 🟢 Also trigger fetch on manual back button press
                        context.read<OrderBloc>().add(
                          const OrdersFetchRequested(),
                        );
                        context.pop();
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(AppConstants.kSpaceLG),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // --- Status Banner ---
                        GlassContainer(
                          padding: const EdgeInsets.all(AppConstants.kSpaceLG),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order #$shortId',
                                    style: AppTextStyles.kHeading3,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedDate,
                                    style: AppTextStyles.kLabelSmall.copyWith(
                                      color: AppColors.kTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              OrderStatusBadgeWidget(status: order.status),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1),

                        const SizedBox(height: AppConstants.kSpaceLG),

                        // --- Tracking Timeline ---
                        Text('Tracking', style: AppTextStyles.kHeading3),
                        const SizedBox(height: AppConstants.kSpaceSM),
                        GlassContainer(
                          padding: const EdgeInsets.all(AppConstants.kSpaceLG),
                          child: _buildTrackingContent(order, progress),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                        const SizedBox(height: AppConstants.kSpaceLG),

                        // --- Items List ---
                        Text('Items', style: AppTextStyles.kHeading3),
                        const SizedBox(height: AppConstants.kSpaceSM),
                        ...order.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppConstants.kSpaceSM,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppConstants.kRadiusLG,
                              ),
                              onTap: () {
                                context.push('/product/${item.productId}');
                              },
                              child: _buildItemCard(item, order!),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppConstants.kSpaceMD),

                        // --- Shipping Address ---
                        Text(
                          'Shipping Address',
                          style: AppTextStyles.kHeading3,
                        ),
                        const SizedBox(height: AppConstants.kSpaceSM),
                        _buildAddressSection(order),

                        const SizedBox(height: AppConstants.kSpaceLG),

                        // --- Payment Summary ---
                        Text('Payment Summary', style: AppTextStyles.kHeading3),
                        const SizedBox(height: AppConstants.kSpaceSM),
                        _buildPaymentSummary(order),

                        const SizedBox(height: AppConstants.kSpaceXL),

                        PrimaryButton(
                          label: 'Order Again',
                          icon: Icons.replay_rounded,
                          onPressed: () async {
                            final cartBloc = context.read<CartBloc>();
                            final messenger = ScaffoldMessenger.of(context);
                            final router = GoRouter.of(context);

                            try {
                              // 1. Clear cart
                              cartBloc.add(const CartCleared());
                              await Future.delayed(
                                const Duration(milliseconds: 300),
                              );

                              if (!mounted) return;

                              // 2. Add items
                              for (var item in order!.items) {
                                cartBloc.add(
                                  CartItemAdded(
                                    productId: item.productId,
                                    quantity: item.quantity,
                                  ),
                                );
                                // Give the Bloc a moment to process each addition
                                await Future.delayed(
                                  const Duration(milliseconds: 100),
                                );
                              }

                              // 3. Navigate
                              if (mounted) {
                                cartBloc.add(const CartFetchRequested());
                                router.go('/cart');
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Cart reset with items from this order!',
                                    ),
                                    backgroundColor: AppColors.kAccentIndigo,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Error reordering items'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: AppConstants.kSpaceMD),

                        // --- Cancel Action (Only for 1 item orders) ---
                        if ((order.status == OrderStatus.pending ||
                                order.status == OrderStatus.confirmed) &&
                            order.items.length == 1)
                          PrimaryButton(
                            label: 'Cancel Order',
                            icon: Icons.cancel_outlined,
                            backgroundColor: Colors.transparent,
                            textColor: AppColors.kError,
                            borderColor: AppColors.kError,
                            onPressed: () => _confirmCancelOrder(context),
                          ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: AppConstants.kSpaceXXL),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingContent(OrderModel order, int progress) {
    if (order.status == OrderStatus.cancelled) {
      return Row(
        children: [
          const Icon(Icons.cancel, color: AppColors.kError, size: 28),
          const SizedBox(width: AppConstants.kSpaceMD),
          Text(
            'This order was cancelled.',
            style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kError),
          ),
        ],
      );
    }
    if (order.status == OrderStatus.returned) {
      return Row(
        children: [
          const Icon(
            Icons.replay_circle_filled,
            color: Colors.redAccent,
            size: 28,
          ),
          const SizedBox(width: AppConstants.kSpaceMD),
          Text(
            'This order was returned.',
            style: AppTextStyles.kBodyMedium.copyWith(color: Colors.redAccent),
          ),
        ],
      );
    }
    return Column(
      children: [
        _buildTimelineStep(
          'Processing',
          'We are processing your order.',
          true,
          isLast: false,
        ),
        _buildTimelineStep(
          'Packed',
          'Your order has been packed.',
          progress >= 2,
          isLast: false,
        ),
        _buildTimelineStep(
          'Out for Delivery',
          order.trackingInfo ?? 'Your item is out for delivery.',
          progress >= 3,
          isLast: false,
        ),
        _buildTimelineStep(
          'Delivered',
          'Your order has been delivered.',
          progress == 4,
          isLast: true,
        ),
      ],
    );
  }

  // 🟢 Updated to accept 'order' and show Cancel Item button dynamically
  Widget _buildItemCard(OrderItemModel item, OrderModel order) {
    final canCancelItem =
        (order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed) &&
        order.items.length > 1;

    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.kSpaceSM),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.kRadiusMD),
                child: CachedNetworkImage(
                  imageUrl: item.image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.kGlassWhite,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.kSpaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.kLabelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${item.quantity}',
                      style: AppTextStyles.kLabelSmall.copyWith(
                        color: AppColors.kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                ((item.price * item.quantity) as num).toDouble().toCurrency(),
                style: AppTextStyles.kBodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // 🟢 Single Item Cancel Button
          if (canCancelItem) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    _confirmCancelItem(context, item.itemId, item.name),
                icon: const Icon(
                  Icons.cancel_outlined,
                  size: 16,
                  color: AppColors.kError,
                ),
                label: Text(
                  'Cancel Item',
                  style: AppTextStyles.kLabelSmall.copyWith(
                    color: AppColors.kError,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressSection(OrderModel order) {
    final addr = order.shippingAddress;
    final line2 = addr.addressLine2 != null && addr.addressLine2!.isNotEmpty
        ? ', ${addr.addressLine2}'
        : '';

    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.kSpaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(addr.fullName, style: AppTextStyles.kLabelLarge),
          const SizedBox(height: 4),
          Text(addr.phone, style: AppTextStyles.kBodyMedium),
          const SizedBox(height: 8),
          Text(
            '${addr.addressLine1}$line2\n${addr.city}, ${addr.state}',
            style: AppTextStyles.kBodyMedium.copyWith(
              color: AppColors.kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(OrderModel order) {
    final double subtotal = order.totalAmount - order.shippingCharge;

    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.kSpaceLG),
      child: Column(
        children: [
          // Subtotal Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: AppTextStyles.kBodyMedium.copyWith(
                  color: AppColors.kTextSecondary,
                ),
              ),
              Text(
                subtotal.toCurrency(),
                style: AppTextStyles.kBodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Shipping Charge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping Charge',
                style: AppTextStyles.kBodyMedium.copyWith(
                  color: AppColors.kTextSecondary,
                ),
              ),
              Text(
                order.shippingCharge == 0
                    ? 'Free'
                    : order.shippingCharge.toCurrency(),
                style: AppTextStyles.kBodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: order.shippingCharge == 0 ? Colors.green : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Payment Method Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Method',
                style: AppTextStyles.kBodyMedium.copyWith(
                  color: AppColors.kTextSecondary,
                ),
              ),
              Text(
                order.paymentMethod,
                style: AppTextStyles.kBodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(color: AppColors.kGlassBorder),
          ),

          // Total Amount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: AppTextStyles.kHeading3),
              Text(
                order.totalAmount.toCurrency(),
                style: AppTextStyles.kHeading2.copyWith(
                  color: AppColors.kAccentIndigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    String title,
    String subtitle,
    bool isCompleted, {
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.kAccentIndigo
                      : AppColors.kGlassWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.kAccentIndigo
                        : AppColors.kGlassBorder,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? AppColors.kAccentIndigo
                        : AppColors.kGlassBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppConstants.kSpaceMD),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.kSpaceLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.kLabelLarge.copyWith(
                      color: isCompleted
                          ? AppColors.kTextPrimary
                          : AppColors.kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.kLabelSmall.copyWith(
                      color: AppColors.kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
