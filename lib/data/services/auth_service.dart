// lib/data/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:front_openerp/core/constants/api_constants.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/services/api_service.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  Future<LoginResultado> login(String email, String password) async {
    try {
      final response = await _apiService.post(ApiEndpoints.login, data: {'email': email, 'password': password});

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Resposta de login inválida');
      }

      final resultado = LoginResultado.fromJson(data);
      if (resultado.contas.isEmpty) {
        throw Exception('Credenciais inválidas: nenhuma conta encontrada para o e-mail informado');
      }
      return resultado;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credenciais inválidas: e-mail ou senha incorretos');
      }
      rethrow;
    }
  }

  Future<void> ativarConta(LoginConta conta) async {
    await _apiService.setToken(conta.token);
    await _apiService.setTokenExpires(conta.expiresAt);
  }

  Future<void> logout() async {
    try {
      await _apiService.post(ApiEndpoints.logout);
    } catch (_) {
      // limpa local mesmo se o back falhar
    }
    await _apiService.logout();
  }

  bool get isAuthenticated => _apiService.isAuthenticated;
}
