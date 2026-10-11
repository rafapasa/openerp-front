// lib/data/repositories/tenant_repository.dart
import 'package:front_openerp/data/models/tenant_llm_config.dart';
import 'package:front_openerp/data/models/tenant_model.dart';
import 'package:front_openerp/data/models/tenant_notificacao_model.dart';
import 'package:front_openerp/data/services/tenant_service.dart';

class TenantRepository {
  final TenantService _service;

  TenantRepository(this._service);

  Future<List<TenantModel>> getAll() async {
    try {
      return await _service.listar();
    } catch (e) {
      throw Exception('Erro ao carregar empresas: $e');
    }
  }

  Future<TenantModel> getById(int id) async {
    try {
      return await _service.obter(id);
    } catch (e) {
      throw Exception('Erro ao buscar empresa: $e');
    }
  }

  Future<TenantModel> create(TenantModel tenant) async {
    try {
      return await _service.criar(tenant);
    } catch (e) {
      throw Exception('Erro ao criar empresa: $e');
    }
  }

  Future<TenantModel> update(TenantModel tenant) async {
    try {
      return await _service.atualizar(tenant);
    } catch (e) {
      throw Exception('Erro ao atualizar empresa: $e');
    }
  }

  Future<TenantModel> updateLlmConfig(int id, TenantLlmConfig config) {
    return _service.atualizarLlmConfig(id, config);
  }

  Future<void> delete(int id) async {
    try {
      await _service.excluir(id);
    } catch (e) {
      throw Exception('Erro ao excluir empresa: $e');
    }
  }

  Future<List<TenantNotificacaoModel>> listarNotificacoes(int tenantId) {
    return _service.listarNotificacoes(tenantId);
  }

  Future<TenantNotificacaoModel> criarNotificacao(int tenantId, Map<String, dynamic> body) {
    return _service.criarNotificacao(tenantId, body);
  }

  Future<TenantNotificacaoModel> atualizarNotificacao(int tenantId, int notifId, Map<String, dynamic> body) {
    return _service.atualizarNotificacao(tenantId, notifId, body);
  }

  Future<void> excluirNotificacao(int tenantId, int notifId) {
    return _service.excluirNotificacao(tenantId, notifId);
  }
}
