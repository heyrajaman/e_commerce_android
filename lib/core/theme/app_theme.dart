import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_constants.dart';
import 'app_text_styles.dart';

class AppTheme {
  // --- LIGHT THEME ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // Keeps the scaffold transparent so your MeshGradientBackground shines through
      scaffoldBackgroundColor: Colors.transparent,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.kAccentIndigo,
        primary: AppColors.kAccentIndigo,
        secondary: AppColors.kAccentPurple,
        tertiary: AppColors.kAccentPink,
        error: AppColors.kError,
        surface: AppColors.kBackground,
      ),

      textTheme: GoogleFonts.interTextTheme(),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.kTextPrimary),
        titleTextStyle: AppTextStyles.kHeading3,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.kGlassWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.kSpaceMD,
          vertical: AppConstants.kSpaceMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.kRadiusMD),
          borderSide: const BorderSide(color: AppColors.kGlassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.kRadiusMD),
          borderSide: const BorderSide(color: AppColors.kGlassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.kRadiusMD),
          borderSide: const BorderSide(
            color: AppColors.kAccentPurple,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.kRadiusMD),
          borderSide: const BorderSide(color: AppColors.kError),
        ),
        hintStyle: AppTextStyles.kBodyMedium.copyWith(
          color: AppColors.kTextSecondary,
        ),
        labelStyle: AppTextStyles.kLabelLarge,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kAccentIndigo,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.kSpaceLG,
            vertical: AppConstants.kSpaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.kRadiusMD),
          ),
          textStyle: AppTextStyles.kButtonText,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.kGlassWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.kRadiusLG),
          side: const BorderSide(color: AppColors.kGlassBorder),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.kTextPrimary,
        contentTextStyle: AppTextStyles.kBodyMedium.copyWith(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.kRadiusSM),
        ),
      ),

      // --- NEW ADAPTIVE UI THEMES ---

      // Adaptive Navigation Bar (Mobile Portrait)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.kGlassWhite,
        indicatorColor: AppColors.kAccentIndigo.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: AppColors.kAccentIndigo, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return const TextStyle(color: AppColors.kTextSecondary, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.kAccentIndigo);
          }
          return const IconThemeData(color: AppColors.kTextSecondary);
        }),
      ),

      // Adaptive Navigation Rail (Tablet/Landscape)
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent, // Handled by GlassContainer wrapper
        useIndicator: true,
        indicatorColor: AppColors.kAccentIndigo.withValues(alpha: 0.2),
        selectedIconTheme: const IconThemeData(color: AppColors.kAccentIndigo),
        unselectedIconTheme: const IconThemeData(color: AppColors.kTextSecondary),
        selectedLabelTextStyle: const TextStyle(color: AppColors.kAccentIndigo, fontWeight: FontWeight.bold),
        unselectedLabelTextStyle: const TextStyle(color: AppColors.kTextSecondary),
      ),

      // Bottom Sheets
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.kSurfaceWhite,
        modalBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.kRadiusXL)),
        ),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.kSurfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.kRadiusLG),
        ),
      ),

      // Tab Bars
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.kAccentIndigo,
        labelColor: AppColors.kAccentIndigo,
        unselectedLabelColor: AppColors.kTextSecondary,
        labelStyle: AppTextStyles.kBodyMedium.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: AppTextStyles.kBodyMedium,
      ),
    );
  }

  // --- DARK THEME (For Future Implementation) ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.kAccentIndigo,
        primary: AppColors.kAccentIndigo,
        secondary: AppColors.kAccentPurple,
        tertiary: AppColors.kAccentPink,
        error: AppColors.kError,
        surface: const Color(0xFF1E1E1E),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
      // (Using standard dark mode defaults for the rest, can be expanded later)
    );
  }
}