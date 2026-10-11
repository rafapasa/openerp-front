// lib/core/config/api_config.dart
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Valores passados via --dart-define
  // Padrão: dev (localhost)
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mcp-server.etoolstec.com.br/api/v1',
  );

  static const String _environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

  static String get baseUrl => _baseUrl;
  static String get environment => _environment;
  static bool get isProd => _environment == 'prod';
  static bool get isDev => _environment == 'dev';

  /// Log para debug
  static void printConfig() {
    if (kDebugMode) {
      debugPrint('🌐 API Config: env=$_environment baseUrl=$_baseUrl');
    }
  }
}
