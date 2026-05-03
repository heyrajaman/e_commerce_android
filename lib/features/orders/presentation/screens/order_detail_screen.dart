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

  void _confirmCancelOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.kGlassWhite,
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Order', style: AppTextStyles.kBodyMedium),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OrderBloc>().add(
                OrderCancelRequested(widget.orderId),
              );
            },
            child: Text(
              'Cancel Order',
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
    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocConsumer<OrderBloc, OrderState>(
          listener: (context, state) {
            if (state is OrderCancelled) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order cancelled successfully'),
                  backgroundColor: AppColors.kError,
                ),
              );
              // 🟢 REFRESH TRIGGER: Fired once here to avoid infinite builder loops
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
            // Check for loading states
            if (state is OrderInitial || state is OrderDetailLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.kAccentIndigo,
                ),
              );
            }

            // Handle Cancelling visual state
            if (state is OrderCancelling || state is OrderCancelled) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.kError),
              );
            }

            // Extract Order data
            OrderModel? order;
            if (state is OrderDetailLoaded) {
              order = state.order;
            } else {
              // Fallback to Bloc memory if available
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
                  title: Text('Order Details', style: AppTextStyles.kHeading2),
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.kTextPrimary,
                    ),
                    onPressed: () => context.pop(),
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
                          child: _buildItemCard(item),
                        ),
                      ),

                      const SizedBox(height: AppConstants.kSpaceMD),

                      // --- Shipping Address ---
                      Text('Shipping Address', style: AppTextStyles.kHeading3),
                      const SizedBox(height: AppConstants.kSpaceSM),
                      _buildAddressSection(order),

                      const SizedBox(height: AppConstants.kSpaceLG),

                      // --- Payment Summary ---
                      Text('Payment Summary', style: AppTextStyles.kHeading3),
                      const SizedBox(height: AppConstants.kSpaceSM),
                      _buildPaymentSummary(order),

                      const SizedBox(height: AppConstants.kSpaceXL),

                      // --- Cancel Action ---
                      if (order.status == OrderStatus.pending ||
                          order.status == OrderStatus.confirmed)
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
          'Order Placed',
          'We have received your order.',
          true,
          isLast: false,
        ),
        _buildTimelineStep(
          'Order Confirmed',
          'Your order has been confirmed.',
          progress >= 2,
          isLast: false,
        ),
        _buildTimelineStep(
          'Shipped',
          order.trackingInfo ?? 'Your item is on the way.',
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

  Widget _buildItemCard(OrderItemModel item) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.kSpaceSM),
      child: Row(
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
    );
  }

  Widget _buildAddressSection(OrderModel order) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.kSpaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.shippingAddress.fullName,
            style: AppTextStyles.kLabelLarge,
          ),
          const SizedBox(height: 4),
          Text(order.shippingAddress.phone, style: AppTextStyles.kBodyMedium),
          const SizedBox(height: 8),
          Text(
            '${order.shippingAddress.addressLine1}${order.shippingAddress.addressLine2 != null ? ', ${order.shippingAddress.addressLine2}' : ''}\n${order.shippingAddress.city}, ${order.shippingAddress.state} - ${order.shippingAddress.pincode}',
            style: AppTextStyles.kBodyMedium.copyWith(
              color: AppColors.kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(OrderModel order) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.kSpaceLG),
      child: Column(
        children: [
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
