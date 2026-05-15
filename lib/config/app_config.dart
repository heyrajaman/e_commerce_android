import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { dev, staging, production }

class AppConfig {
  // 1. Prod Fix: Automatically detect if the app is a release build to prevent shipping dev URLs to live users.
  static AppEnvironment get currentEnvironment {
    if (kReleaseMode) return AppEnvironment.production;
    if (kProfileMode) return AppEnvironment.staging;
    return AppEnvironment.dev;
  }

  // 2. Security: Prioritize the .env file for the Base URL so production URLs aren't hardcoded in git.
  static String get kBaseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    // Fallbacks if .env is missing the API_BASE_URL key
    switch (currentEnvironment) {
      case AppEnvironment.dev:
        return 'http://10.0.2.2:5007';
      case AppEnvironment.staging:
        return 'https://staging-api.yourdomain.com';
      case AppEnvironment.production:
        return 'https://api.yourdomain.com';
    }
  }

  // 3. New: Securely expose the Razorpay Key from the .env file for your checkout logic
  static String get razorpayKeyId {
    final key = dotenv.env['RAZORPAY_KEY_ID'];
    if (key == null || key.isEmpty) {
      // Standardize empty returns rather than nulls to prevent UI null assertion crashes
      return '';
    }
    return key;
  }

  // 4. Platform & SonarQube Fix: Prevent unsupported dart:io crashes on non-mobile platforms
  static String sanitizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    // Only apply the localhost replacement if we are strictly in dev, NOT on the web, and ON an Android device.
    if (currentEnvironment == AppEnvironment.dev &&
        !kIsWeb &&
        Platform.isAndroid) {
      return url
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
    }

    return url;
  }
}
