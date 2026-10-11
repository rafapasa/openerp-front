import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:front_openerp/core/config/api_config.dart';
import 'package:front_openerp/data/repositories/local_storage.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  // static const String baseUrl = 'https://mcp-server.etoolstec.com.br/api/v1';
  //  static const String baseUrl = 'http://localhost:8082/api/v1';
  static String get baseUrl => ApiConfig.baseUrl;
  static const String defaultTenantId = '0';

  late final Dio _dio;
  final Uuid _uuid = const Uuid();

  ApiService() {
    ApiConfig.printConfig();
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'X-Tenant-ID': defaultTenantId},
      ),
    );

    // Interceptor para log (útil para debug)
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(request: true, requestHeader: true, requestBody: true, responseHeader: true, responseBody: true),
      );
    }

    // Interceptor para adicionar token automaticamente
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Headers exigidos pelos middlewares do Fiber.
          final tenantId = LocalStorage.getData<dynamic>('tenant_ativo_id');
          options.headers['X-Tenant-ID'] = tenantId?.toString() ?? defaultTenantId;
          options.headers['X-Request-ID'] = _uuid.v4();

          // Token persistido no LocalStorage (fonte única, junto com a expiração).
          final token = LocalStorage.getToken();

          // Adicionar token no header se existir
          if (token != null && token.isNotEmpty && !options.path.contains('/login')) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          final code = error.response?.statusCode;
          final path = error.requestOptions.path;
          if (path.contains('/login')) {
            return handler.next(error);
          }
          if (code == 401 || code == 403) {
            await _clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Getters
  Dio get dio => _dio;

  // Gerenciar token (persistido no LocalStorage/Hive)
  Future<void> setToken(String token) async {
    await LocalStorage.setToken(token);
  }

  Future<void> setTokenExpires(String tokenExpires) async {
    await LocalStorage.setTokenExpires(tokenExpires);
  }

  Future<void> _clearToken() async {
    await LocalStorage.clearToken();
    await LocalStorage.clearTokenExpires();
  }

  Future<void> logout() async {
    await _clearToken();
  }

  // Métodos genéricos para requisições
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.patch(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Tratamento de erros
  Exception _handleError(DioException error) {
    String message = 'Ocorreu um erro inesperado';

    if (error.response != null) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      switch (statusCode) {
        case 400:
          message = data?['error'] ?? 'Dados inválidos';
          break;
        case 401:
          message = 'Sessão expirada. Faça login novamente.';
          break;
        case 403:
          message = 'Você não tem permissão para acessar este recurso';
          break;
        case 404:
          message = 'Recurso não encontrado';
          break;
        case 500:
          message = 'Erro no servidor. Tente novamente mais tarde.';
          break;
        default:
          message = data?['error'] ?? data?['message'] ?? message;
      }
    } else if (error.type == DioExceptionType.connectionTimeout || error.type == DioExceptionType.receiveTimeout) {
      message = 'Tempo de conexão esgotado. Verifique sua internet.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Erro de conexão. Verifique sua internet.';
    }

    return Exception(message);
  }

  // ============================================================
  // 🔎 Verificar autenticação
  // ============================================================
  // Checa o token persistido (LocalStorage/Hive) e a data de expiração.
  // Não depende de variável em memória, então funciona logo no boot do app,
  // antes de qualquer requisição HTTP.
  bool get isAuthenticated => LocalStorage.hasValidToken();
}
