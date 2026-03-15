enum AppEnvironment { development, production }

class EnvironmentConfig {
  static AppEnvironment environment = AppEnvironment.development;

  static bool get isDevelopment => environment == AppEnvironment.development;
  static bool get isProduction => environment == AppEnvironment.production;
}
