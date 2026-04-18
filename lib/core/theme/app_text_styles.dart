import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  // Base Inter font with the primary text color applied
  static TextStyle get _base => GoogleFonts.inter(
    color: AppColors.kTextPrimary,
  );

  // --- Headings ---
  static TextStyle get kHeading1 => _base.copyWith(
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static TextStyle get kHeading2 => _base.copyWith(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static TextStyle get kHeading3 => _base.copyWith(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // --- Body Text ---
  static TextStyle get kBodyLarge => _base.copyWith(
    fontSize: 18.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle get kBodyMedium => _base.copyWith(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle get kBodySmall => _base.copyWith(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.kTextSecondary, // Usually secondary for small body text
  );

  // --- Labels (Forms & Meta) ---
  static TextStyle get kLabelLarge => _base.copyWith(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get kLabelSmall => _base.copyWith(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: AppColors.kTextSecondary,
  );

  // --- Buttons ---
  static TextStyle get kButtonText => _base.copyWith(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}