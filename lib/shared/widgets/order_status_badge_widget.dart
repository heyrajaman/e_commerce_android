import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/order_model.dart';

class OrderStatusBadgeWidget extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadgeWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case OrderStatus.pending:
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        text = 'Pending';
        break;
      case OrderStatus.confirmed:
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        text = 'Confirmed';
        break;
      case OrderStatus.shipped:
        bgColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        text = 'Shipped';
        break;
      case OrderStatus.delivered:
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        text = 'Delivered';
        break;
      case OrderStatus.cancelled:
        bgColor = AppColors.kError.withValues(alpha: 0.1);
        textColor = AppColors.kError;
        text = 'Cancelled';
        break;
      case OrderStatus.returned:
        bgColor = Colors.redAccent.withValues(alpha: 0.1);
        textColor = Colors.redAccent;
        text = 'Returned';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: textColor),
          const SizedBox(width: 6),
          // 🟢 Added Flexible and ellipsis to prevent the 14px overflow
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.kLabelSmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
