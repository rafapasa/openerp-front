// lib/data/repositories/auth_repository.dart
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/repositories/local_storage.dart';
import 'package:front_openerp/data/services/services.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  Future<LoginResultado> login(String email, String password) async {
    return await _authService.login(email, password);
  }

  Future<UsuarioModel> ativarConta(LoginConta conta) async {
    await _authService.ativarConta(conta);
    await LocalStorage.setToken(conta.token);
    await LocalStorage.setTokenExpires(conta.expiresAt);
    await LocalStorage.saveData('tenant_ativo_id', conta.tenant.id);
    final usuario = UsuarioModel.fromLoginConta(conta);
    await LocalStorage.saveData('usuario', usuario.toJson());
    return usuario;
  }

  Future<void> salvarContas(List<LoginConta> contas) async {
    await LocalStorage.saveData(LocalStorage.contasLoginKey, contas.map((c) => c.toJson()).toList());
  }

  Future<List<LoginConta>?> getContas() async {
    final cached = LocalStorage.getData<List<dynamic>>(LocalStorage.contasLoginKey);
    if (cached == null) return null;
    try {
      return cached.whereType<Map<String, dynamic>>().map(LoginConta.fromJson).toList();
    } catch (e) {
      return null;
    }
  }

  Future<UsuarioModel> selectTenant(int tenantId) async {
    final contas = await getContas() ?? const <LoginConta>[];
    LoginConta? conta;
    for (final c in contas) {
      if (c.tenant.id == tenantId) {
        conta = c;
        break;
      }
    }
    if (conta == null) {
      throw Exception('Conta não encontrada para o tenant $tenantId');
    }
    return await ativarConta(conta);
  }

  Future<UsuarioModel?> getCurrentUser() async {
    final cached = LocalStorage.getData<Map<String, dynamic>>('usuario');
    if (cached != null) {
      return UsuarioModel.fromJson(cached);
    }
    return null;
  }

  Future<void> desativarContaAtual() async {
    await LocalStorage.clearToken();
    await LocalStorage.clearTokenExpires();
    await LocalStorage.clearCache('usuario');
    await LocalStorage.clearCache('tenant_ativo_id');
  }

  Future<void> logout() async {
    await _authService.logout();
    await LocalStorage.clearToken();
    await LocalStorage.clearCache('usuario');
    await LocalStorage.clearCache('tenant_ativo_id');
    await LocalStorage.clearAll();
  }

  bool get isAuthenticated => LocalStorage.hasValidToken();

  bool isTokenExpired() => LocalStorage.isTokenExpired();

  Future<bool> restoreSession() async {
    final token = LocalStorage.getToken();
    if (token != null && token.isNotEmpty) {
      final user = await getCurrentUser();
      return user != null;
    }
    return false;
  }
}
