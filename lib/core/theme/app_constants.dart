import 'package:flutter/material.dart';

class AppConstants {
  // --- Spacing Scale ---
  static const double kSpaceXS = 4.0;
  static const double kSpaceSM = 8.0;
  static const double kSpaceMD = 16.0;
  static const double kSpaceLG = 24.0;
  static const double kSpaceXL = 32.0;
  static const double kSpaceXXL = 48.0;

  // --- Border Radius ---
  static const double kRadiusSM = 8.0;
  static const double kRadiusMD = 12.0;
  static const double kRadiusLG = 16.0;
  static const double kRadiusXL = 24.0;

  // --- Glassmorphism Effect Values ---
  static const double kGlassBlur = 16.0;
  static const double kGlassOpacity = 0.65;
  static const double kGlassBorderOpacity = 0.4;

  // Premium subtle shadow matching the web's box-shadow: 0 4px 30px rgba(0, 0, 0, 0.05)
  static const BoxShadow kGlassShadow = BoxShadow(
    color: Color(0x0D000000), // 5% black
    offset: Offset(0, 4),
    blurRadius: 30.0,
    spreadRadius: 0.0,
  );

  // --- Animation Durations ---
  static const Duration kAnimFast = Duration(milliseconds: 200);
  static const Duration kAnimNormal = Duration(milliseconds: 400);
  static const Duration kAnimSlow = Duration(milliseconds: 1500); // Matches the 1.5s web animations
}