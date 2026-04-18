import 'package:flutter/material.dart';

class AppColors {
  // Base Colors
  static const Color kBackground = Color(0xFFF8FAFC); // Light Slate
  static const Color kTextPrimary = Color(0xFF1E293B); // Dark Slate
  static const Color kTextSecondary = Color(0xFF64748B);

  // Accent Colors
  static const Color kAccentIndigo = Color(0xFF6366F1);
  static const Color kAccentPurple = Color(0xFF8B5CF6);
  static const Color kAccentPink = Color(0xFFEC4899);

  // Status Colors
  static const Color kError = Color(0xFFDC2626);
  static const Color kSuccess = Color(0xFF16A34A);

  // Glassmorphism Colors (using calculated ARGB hex for const support)
  // 0.65 opacity * 255 = 166 = 0xA6
  static const Color kGlassWhite = Color(0xA6FFFFFF);
  // 0.40 opacity * 255 = 102 = 0x66
  static const Color kGlassBorder = Color(0x66FFFFFF);

  // Mesh Gradient Colors
  // 0.15 opacity * 255 = 38 = 0x26
  static const Color kMeshIndigo = Color(0x266366F1);
  static const Color kMeshPurple = Color(0x268B5CF6);
  static const Color kMeshPink = Color(0x26EC4899);

  static const Color kSurfaceWhite = Colors.white;
}