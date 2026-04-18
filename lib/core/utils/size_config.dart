import 'package:flutter/material.dart';

class SizeConfig {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeH;
  static late double blockSizeV;

  // Initialize this inside the build method of your root widget (e.g., inside MainLayoutScreen or MaterialApp)
  static void setScreenSize(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;

    // 1% of the screen width and height
    blockSizeH = screenWidth / 100;
    blockSizeV = screenHeight / 100;
  }

  /// Get the proportionate height as per screen size.
  /// 812.0 is the standard layout height that designers use (e.g., iPhone 11/12 Pro).
  static double getProportionateScreenHeight(double inputHeight) {
    double layoutHeight = 812.0;
    return (inputHeight / layoutHeight) * screenHeight;
  }

  /// Get the proportionate width as per screen size.
  /// 375.0 is the standard layout width that designers use (e.g., iPhone 11/12 Pro).
  static double getProportionateScreenWidth(double inputWidth) {
    double layoutWidth = 375.0;
    return (inputWidth / layoutWidth) * screenWidth;
  }
}