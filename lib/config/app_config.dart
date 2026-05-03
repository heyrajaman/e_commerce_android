import 'dart:io'; // Add this import at the top

enum AppEnvironment { dev, staging, production }

class AppConfig {
  static const AppEnvironment currentEnvironment = AppEnvironment.dev;

  static String get kBaseUrl {
    switch (currentEnvironment) {
      case AppEnvironment.dev:
        return 'http://10.0.2.2:5007';
      case AppEnvironment.staging:
        return 'https://staging-api.yourdomain.com';
      case AppEnvironment.production:
        return 'https://api.yourdomain.com';
    }
  }

  // Add this helper method
  static String sanitizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    // If we are in dev and on Android, replace localhost with 10.0.2.2
    if (currentEnvironment == AppEnvironment.dev && Platform.isAndroid) {
      return url
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
    }

    return url;
  }
}
