import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import 'glass_container.dart';

class CategoryChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        // We set padding to zero here because the AnimatedContainer will handle it
        padding: EdgeInsets.zero,
        // Using a more rounded radius for a "pill" chip look
        borderRadius: AppConstants.kRadiusXL,
        child: AnimatedContainer(
          duration: AppConstants.kAnimFast,
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.kSpaceLG,
            vertical: AppConstants.kSpaceSM,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.kRadiusXL),
            // Smoothly animate the gradient in and out
            gradient: isSelected
                ? const LinearGradient(
              colors: [AppColors.kAccentIndigo, AppColors.kAccentPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : const LinearGradient(
              // Transparent gradient so the GlassContainer shows through when unselected
              colors: [Colors.transparent, Colors.transparent],
            ),
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: AppConstants.kAnimFast,
              style: AppTextStyles.kLabelLarge.copyWith(
                color: isSelected ? Colors.white : AppColors.kTextSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}