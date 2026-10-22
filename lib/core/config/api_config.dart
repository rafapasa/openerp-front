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

  /// Dev = dart-define ENVIRONMENT=dev OU API de teste/local.
  /// Usado para exibir ações só de ambiente de teste (ex.: Usar como webhook).
  static bool get isDev {
    if (_environment == 'prod') return false;
    if (_environment == 'dev') return true;
    final u = _baseUrl.toLowerCase();
    return u.contains('teste') || u.contains('localhost') || u.contains('127.0.0.1');
  }

  /// Log para debug
  static void printConfig() {
    if (kDebugMode) {
      debugPrint('🌐 API Config: env=$_environment baseUrl=$_baseUrl isDev=$isDev');
    }
  }
}
