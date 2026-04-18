import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import 'glass_container.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The underlying screen content
        child,

        // 2. The animated overlay
        Positioned.fill(
          child: IgnorePointer(
            // When not loading, let touches pass through to the child
            ignoring: !isLoading,
            child: AnimatedOpacity(
              opacity: isLoading ? 1.0 : 0.0,
              duration: AppConstants.kAnimNormal,
              curve: Curves.easeInOut,
              child: Container(
                color: Colors.black.withValues(alpha: 0.3), // Semi-transparent dimming
                child: Center(
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.kSpaceXL,
                      vertical: AppConstants.kSpaceLG,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.kAccentIndigo,
                        ),
                        if (message != null) ...[
                          const SizedBox(height: AppConstants.kSpaceMD),
                          Text(
                            message!,
                            style: AppTextStyles.kBodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}