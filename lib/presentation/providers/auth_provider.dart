// lib/presentation/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/models/tenant_model.dart';
import 'package:front_openerp/data/repositories/repositories.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  UsuarioModel? _usuario;
  List<LoginConta> _contas = [];
  bool _isLoading = false;
  String? _error;
  bool _tenantSelecionado = false;

  UsuarioModel? get usuario => _usuario;
  List<LoginConta> get contas => _contas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _authRepository.isAuthenticated;

  bool get hasMultipleTenants => _contas.length > 1 || (_usuario?.tenants?.length ?? 0) > 1;
  bool get precisaSelecionarConta => hasMultipleTenants && !_tenantSelecionado;
  bool get tenantSelecionado => _tenantSelecionado;
  List<TenantModel>? get tenants => _usuario?.tenants;
  TenantModel? get tenantAtivo => _usuario?.tenantAtivo;

  AuthProvider(this._authRepository) {
    _init();
  }

  Future<void> _init() async {
    await restoreSession();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    _tenantSelecionado = false;
    _contas = [];

    try {
      final resultado = await _authRepository.login(email, password);
      _contas = resultado.contas;

      if (resultado.contas.length == 1) {
        _usuario = await _authRepository.ativarConta(resultado.contas.first);
        await _authRepository.salvarContas(resultado.contas);
        _tenantSelecionado = true;
      } else {
        await _authRepository.salvarContas(resultado.contas);
        _usuario = null;
        _tenantSelecionado = false;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> selectTenant(int tenantId) async {
    _setLoading(true);
    _clearError();

    try {
      _usuario = await _authRepository.selectTenant(tenantId);
      _tenantSelecionado = true;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> trocarEmpresa() async {
    _setLoading(true);
    try {
      var contas = _contas;
      if (contas.isEmpty) {
        contas = await _authRepository.getContas() ?? const [];
      }
      await _authRepository.desativarContaAtual();
      _usuario = null;
      _tenantSelecionado = false;
      _contas = contas;
      _clearError();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authRepository.logout();
      _usuario = null;
      _contas = [];
      _tenantSelecionado = false;
      _clearError();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> restoreSession() async {
    _setLoading(true);
    try {
      final restored = await _authRepository.restoreSession();
      if (restored) {
        final user = await _authRepository.getCurrentUser();
        _usuario = user;
        final contas = await _authRepository.getContas();
        _contas = contas ?? const [];
        _tenantSelecionado = user?.tenantAtivoId != null;
      }
      _setLoading(false);
      notifyListeners();
      return restored;
    } catch (e) {
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
