enum AppEnvironment { dev, staging, production }

class AppConfig {
  // Toggle this to switch environments easily
  static const AppEnvironment currentEnvironment = AppEnvironment.dev;

  static String get kBaseUrl {
    switch (currentEnvironment) {
      case AppEnvironment.dev:
      // Use 10.0.2.2 for Android Studio emulator to reach localhost:5007
        return 'http://10.0.2.2:5007';
      case AppEnvironment.staging:
        return 'https://staging-api.yourdomain.com';
      case AppEnvironment.production:
        return 'https://api.yourdomain.com';
    }
  }
}