// lib/presentation/providers/tenant_provider.dart
import 'package:flutter/material.dart';
import 'package:front_openerp/data/models/tenant_llm_config.dart';
import 'package:front_openerp/data/models/tenant_model.dart';
import 'package:front_openerp/data/models/tenant_notificacao_model.dart';
import 'package:front_openerp/data/repositories/tenant_repository.dart';

class TenantProvider extends ChangeNotifier {
  final TenantRepository _repository;

  List<TenantModel> _tenants = [];
  bool _isLoading = false;
  String? _error;
  TenantModel? _selectedTenant;

  TenantProvider(this._repository);

  List<TenantModel> get tenants => _tenants;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TenantModel? get selectedTenant => _selectedTenant;
  bool get hasError => _error != null;
  bool get isEmpty => _tenants.isEmpty && !_isLoading;

  Future<void> carregarTenants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tenants = await _repository.getAll();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _tenants = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> criarTenant(TenantModel tenant) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final novo = await _repository.create(tenant);
      _tenants.insert(0, novo);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> atualizarTenant(TenantModel tenant) async {
    if (tenant.id == null) {
      _error = 'ID da empresa não fornecido';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final atualizado = await _repository.update(tenant);
      final index = _tenants.indexWhere((t) => t.id == tenant.id);
      if (index != -1) {
        _tenants[index] = atualizado;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> excluirTenant(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.delete(id);
      _tenants.removeWhere((t) => t.id == id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selecionarTenant(int id) async {
    try {
      _selectedTenant = await _repository.getById(id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void limparSelecao() {
    _selectedTenant = null;
    notifyListeners();
  }

  void reset() {
    _tenants = [];
    _isLoading = false;
    _error = null;
    _selectedTenant = null;
    notifyListeners();
  }

  Future<List<TenantNotificacaoModel>> listarNotificacoes(int tenantId) async {
    try {
      return await _repository.listarNotificacoes(tenantId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<TenantModel?> atualizarLlmConfig(int tenantId, TenantLlmConfig config) async {
    try {
      final atualizado = await _repository.updateLlmConfig(tenantId, config);
      final index = _tenants.indexWhere((t) => t.id == tenantId);
      if (index != -1) {
        _tenants[index] = atualizado;
      }
      _error = null;
      notifyListeners();
      return atualizado;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<TenantNotificacaoModel?> criarNotificacao(int tenantId, Map<String, dynamic> body) async {
    try {
      return await _repository.criarNotificacao(tenantId, body);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<TenantNotificacaoModel?> atualizarNotificacao(int tenantId, int notifId, Map<String, dynamic> body) async {
    try {
      return await _repository.atualizarNotificacao(tenantId, notifId, body);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> excluirNotificacao(int tenantId, int notifId) async {
    try {
      await _repository.excluirNotificacao(tenantId, notifId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
