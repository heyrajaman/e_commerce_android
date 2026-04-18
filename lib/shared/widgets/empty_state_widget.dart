import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import 'glass_container.dart';
import 'primary_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  // --- Pre-built Named Constructors ---

  factory EmptyStateWidget.emptyCart({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.shopping_cart_outlined,
      title: 'Your cart is empty',
      subtitle: 'Looks like you haven\'t added anything to your cart yet. Discover our latest products!',
      actionLabel: 'Start Shopping',
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.noOrders({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.receipt_long_outlined,
      title: 'No orders yet',
      subtitle: 'When you place an order, it will safely appear here.',
      actionLabel: 'Shop Now',
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.noProducts({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.inventory_2_outlined,
      title: 'No products found',
      subtitle: 'We couldn\'t find any products matching your current filters or category.',
      actionLabel: 'Clear Filters',
      onAction: onAction,
    );
  }

  factory EmptyStateWidget.noSearchResults(String query, {VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: 'No results found',
      subtitle: 'We couldn\'t find anything for "$query". Try searching with different keywords.',
      actionLabel: 'Clear Search',
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.kSpaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Takes only needed height
          children: [
            // Circular Glass Icon Container
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: GlassContainer(
                padding: const EdgeInsets.all(AppConstants.kSpaceXL),
                child: Icon(
                  icon,
                  size: 80,
                  color: AppColors.kTextSecondary.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.kSpaceLG),

            // Title
            Text(
              title,
              style: AppTextStyles.kHeading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.kSpaceSM),

            // Subtitle
            Text(
              subtitle,
              style: AppTextStyles.kBodyMedium.copyWith(
                color: AppColors.kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.kSpaceXL),

            // Optional Action Button
            if (actionLabel != null && onAction != null)
              SizedBox(
                width: 220, // Keep button size consistent and elegant
                child: PrimaryButton(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ),
          ],
        ).animate().fadeIn(duration: AppConstants.kAnimNormal).slideY(begin: 0.1),
      ),
    );
  }
}