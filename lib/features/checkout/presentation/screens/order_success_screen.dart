import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/mesh_gradient_background.dart';
import '../../../../shared/widgets/primary_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents the user from swiping back to the checkout form
      child: MeshGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.kSpaceLG),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Checkmark
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 120,
                  )
                      .animate()
                      .scale(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                  )
                      .fadeIn(),

                  const SizedBox(height: AppConstants.kSpaceLG),

                  // Success Heading
                  Text(
                    'Order Placed Successfully! 🎉',
                    style: AppTextStyles.kHeading2,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 300)).slideY(begin: 0.2),

                  const SizedBox(height: AppConstants.kSpaceSM),
                  Text(
                    'Thank you for your purchase.',
                    style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondary),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 400)),

                  const SizedBox(height: AppConstants.kSpaceXL),

                  // Order ID Card
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.kSpaceXL,
                      vertical: AppConstants.kSpaceMD,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Order ID',
                          style: AppTextStyles.kLabelSmall.copyWith(color: AppColors.kTextSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          orderId,
                          style: AppTextStyles.kHeading3.copyWith(color: AppColors.kAccentIndigo),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 500)).scale(begin: const Offset(0.9, 0.9)),

                  const SizedBox(height: AppConstants.kSpaceXXL),

                  // Action Buttons
                  PrimaryButton(
                    label: 'Track My Order',
                    icon: Icons.local_shipping_outlined,
                    onPressed: () {
                      // Note: We'll implement the orders feature later.
                      // For now, this can act as a placeholder.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order tracking coming soon!')),
                      );
                    },
                  ).animate().fadeIn(delay: const Duration(milliseconds: 600)),

                  const SizedBox(height: AppConstants.kSpaceMD),

                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      'Continue Shopping',
                      style: AppTextStyles.kButtonText.copyWith(color: AppColors.kAccentPurple),
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}