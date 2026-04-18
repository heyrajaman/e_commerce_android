import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = AppConstants.kRadiusLG,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      // Apply the subtle drop shadow on the outer container
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [AppConstants.kGlassShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          // The CSS backdrop-filter: blur(16px) equivalent
          filter: ImageFilter.blur(
            sigmaX: AppConstants.kGlassBlur,
            sigmaY: AppConstants.kGlassBlur,
          ),
          child: Container(
            width: width,
            height: height,
            padding: padding ?? const EdgeInsets.all(AppConstants.kSpaceMD),
            decoration: BoxDecoration(
              color: AppColors.kGlassWhite,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppColors.kGlassBorder,
                width: 1.0, // 1px solid rgba(255, 255, 255, 0.4)
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}