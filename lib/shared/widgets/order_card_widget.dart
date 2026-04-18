import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/order_model.dart';
import 'glass_container.dart';
import 'order_status_badge_widget.dart';

class OrderCardWidget extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const OrderCardWidget({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Safely format the order ID (e.g., take the last 6 characters)
    final shortId = order.id.length > 6
        ? order.id.substring(order.id.length - 6).toUpperCase()
        : order.id.toUpperCase();

    // Format the date
    final formattedDate = DateFormat('dd MMM yyyy').format(order.createdAt);

    // Calculate total item quantity
    final totalQuantity = order.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(AppConstants.kSpaceLG),
        child: Row(
          children: [
            // Left Side: Order Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#ORD-$shortId',
                        style: AppTextStyles.kLabelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextPrimary,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: AppTextStyles.kLabelSmall.copyWith(
                          color: AppColors.kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.kSpaceSM),

                  // Total Amount and Items count
                  Row(
                    children: [
                      Text(
                        '\$${order.totalAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.kHeading3.copyWith(
                          color: AppColors.kAccentIndigo,
                        ),
                      ),
                      const SizedBox(width: AppConstants.kSpaceSM),
                      Text(
                        '• $totalQuantity ${totalQuantity == 1 ? 'item' : 'items'}',
                        style: AppTextStyles.kBodyMedium.copyWith(
                          color: AppColors.kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.kSpaceMD),

                  // Status Badge
                  OrderStatusBadgeWidget(status: order.status),
                ],
              ),
            ),

            const SizedBox(width: AppConstants.kSpaceMD),

            // Right Side: Chevron Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.kGlassWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.kGlassBorder),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: AppColors.kTextSecondary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppConstants.kAnimNormal).slideY(begin: 0.1);
  }
}