import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import 'glass_container.dart';
import 'primary_button.dart';

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.kSpaceLG),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppConstants.kSpaceXL),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Keep the card wrapped tightly around its content
            children: [
              // Error Icon in a tinted circle
              Container(
                padding: const EdgeInsets.all(AppConstants.kSpaceMD),
                decoration: BoxDecoration(
                  color: AppColors.kError.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: AppColors.kError,
                ),
              ),
              const SizedBox(height: AppConstants.kSpaceLG),

              // Standard Error Title
              Text(
                'Oops! Something went wrong.',
                style: AppTextStyles.kHeading3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.kSpaceSM),

              // Dynamic Error Message
              Text(
                message,
                style: AppTextStyles.kBodyMedium.copyWith(
                  color: AppColors.kTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.kSpaceXL),

              // Retry Button (Only show if a callback is provided)
              if (onRetry != null)
                SizedBox(
                  width: 200,
                  child: PrimaryButton(
                    label: 'Try Again',
                    icon: Icons.refresh_rounded,
                    onPressed: onRetry,
                    // Making it visually distinct using our new button properties
                    backgroundColor: Colors.transparent,
                    textColor: AppColors.kTextPrimary,
                    borderColor: AppColors.kTextSecondary.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        ).animate()
            .fadeIn(duration: AppConstants.kAnimNormal)
            .shakeX(amount: 4, duration: const Duration(milliseconds: 400)), // Subtle shake to indicate error
      ),
    );
  }
}