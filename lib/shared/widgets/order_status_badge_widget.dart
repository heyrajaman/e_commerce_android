import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/order_model.dart';
import 'glass_container.dart';

class OrderStatusBadgeWidget extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadgeWidget({super.key, required this.status});

  Color _getStatusColor() {
    switch (status) {
      case OrderStatus.pending:
        return Colors.amber.shade700;
      case OrderStatus.confirmed:
        return AppColors.kAccentIndigo;
      case OrderStatus.shipped:
        return Colors.blue.shade600;
      case OrderStatus.delivered:
        return Colors.green.shade600;
      case OrderStatus.cancelled:
        return AppColors.kError;
    }
  }

  String _getStatusText() {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final text = _getStatusText();

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), // ✅ replaces GlassContainer.color
        border: Border.all(
          color: color.withValues(alpha: 0.3), // ✅ replaces GlassContainer.border
        ),
        borderRadius: BorderRadius.circular(AppConstants.kRadiusMD),
      ),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.kSpaceSM,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4), // ✅ already correct
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppTextStyles.kLabelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}