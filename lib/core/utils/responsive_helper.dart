import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Breakpoints
  static const double kMobileMaxWidth = 600;
  static const double kTabletMaxWidth = 1024;
  static const double kDesktopMinWidth = 1025;

  // Screen Types
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width <= kMobileMaxWidth;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > kMobileMaxWidth && width <= kTabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= kDesktopMinWidth;
  }

  // Orientations
  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.portrait;
  }

  // Dimensions
  static double screenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  // Percentages
  static double hp(BuildContext context, double percent) {
    return MediaQuery.sizeOf(context).height * (percent / 100);
  }

  static double wp(BuildContext context, double percent) {
    return MediaQuery.sizeOf(context).width * (percent / 100);
  }

  // Adaptive Padding
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 64);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16);
    }
  }
}