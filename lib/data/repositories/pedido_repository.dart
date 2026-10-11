// lib/data/repositories/pedido_repository.dart
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/repositories/local_storage.dart';
import 'package:front_openerp/data/services/services.dart';

class PedidoRepository {
  final PedidoService _pedidoService;

  PedidoRepository(this._pedidoService);

  // ============================================================
  // 📋 Listar Pedidos (com cache)
  // ============================================================
  Future<PaginatedResponse<PedidoModel>> getPedidos({
    int page = 1,
    int limit = 20,
    String? status,
    int? clienteId,
    String? dataInicio,
    String? dataFim,
    bool forceRefresh = false,
  }) async {
    // Cache apenas para página 1 sem filtros
    if (!forceRefresh &&
        page == 1 &&
        status == null &&
        clienteId == null &&
        LocalStorage.isCacheValid(LocalStorage.pedidosKey)) {
      final cached = LocalStorage.getData<List<dynamic>>(LocalStorage.pedidosKey);
      if (cached != null) {
        final data = cached.map((e) => PedidoModel.fromJson(e as Map<String, dynamic>)).toList();
        return PaginatedResponse<PedidoModel>(data: data, total: data.length, page: 1, limit: data.length, pages: 1);
      }
    }

    // Buscar da API
    try {
      final pedidos = await _pedidoService.getPedidos(
        page: page,
        limit: limit,
        status: status,
        clienteId: clienteId,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      // Salvar no cache apenas para página 1
      if (page == 1 && status == null && clienteId == null) {
        await LocalStorage.saveData(LocalStorage.pedidosKey, pedidos.data.map((e) => e.toJson()).toList());
      }

      return pedidos;
    } catch (e) {
      // Se falhou e tem cache, usar cache
      if (page == 1) {
        final cached = LocalStorage.getData<List<dynamic>>(LocalStorage.pedidosKey);
        if (cached != null) {
          final data = cached.map((e) => PedidoModel.fromJson(e as Map<String, dynamic>)).toList();
          return PaginatedResponse<PedidoModel>(data: data, total: data.length, page: 1, limit: data.length, pages: 1);
        }
      }
      rethrow;
    }
  }

  // ============================================================
  // 🔍 Buscar Pedido por ID
  // ============================================================
  Future<PedidoModel> getPedidoById(int id) async {
    // Verificar se está no cache
    final cached = LocalStorage.getData<List<dynamic>>(LocalStorage.pedidosKey);
    if (cached != null) {
      try {
        final pedido = cached.firstWhere((e) => e['id'] == id, orElse: () => null);
        if (pedido != null) {
          return PedidoModel.fromJson(pedido as Map<String, dynamic>);
        }
      } catch (e) {
        // Não encontrado no cache, buscar da API
      }
    }

    // Buscar da API
    try {
      return await _pedidoService.getPedidoById(id);
    } catch (e) {
      // Se falhou e tem cache, usar mesmo assim
      final cached = LocalStorage.getData<List<dynamic>>(LocalStorage.pedidosKey);
      if (cached != null) {
        final pedido = cached.firstWhere((e) => e['id'] == id, orElse: () => null);
        if (pedido != null) {
          return PedidoModel.fromJson(pedido as Map<String, dynamic>);
        }
      }
      rethrow;
    }
  }

  // ============================================================
  // 📝 Atualizar Status
  // ============================================================
  Future<PedidoModel> updateStatus(int id, StatusPedido status, {String? motivo}) async {
    try {
      final pedido = await _pedidoService.updateStatusPedido(id, status, motivo: motivo);

      // Atualizar cache se existir
      final cached = LocalStorage.getData<List<dynamic>>(LocalStorage.pedidosKey);
      if (cached != null) {
        final updatedCached = cached.map((e) {
          if (e['id'] == id) {
            return pedido.toJson();
          }
          return e;
        }).toList();
        await LocalStorage.saveData(LocalStorage.pedidosKey, updatedCached);
      }

      return pedido;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // 🗑️ Limpar cache
  // ============================================================
  Future<PedidoModel> marcarPago(int id, {int? formaPagamentoId, double? valor, String? observacao}) {
    return _pedidoService.marcarPago(id, formaPagamentoId: formaPagamentoId, valor: valor, observacao: observacao);
  }

  Future<PedidoModel> createPedido({
    required int clienteId,
    required String clienteNome,
    String clienteTelefone = '',
    required List<Map<String, dynamic>> itens,
    String? observacoes,
    int? enderecoEntregaId,
    String origem = 'dashboard',
    String? etiqueta,
  }) {
    return _pedidoService.createPedido(
      clienteId: clienteId,
      clienteNome: clienteNome,
      clienteTelefone: clienteTelefone,
      itens: itens,
      observacoes: observacoes,
      enderecoEntregaId: enderecoEntregaId,
      origem: origem,
      etiqueta: etiqueta,
    );
  }

  Future<void> clearCache() async {
    await LocalStorage.clearCache(LocalStorage.pedidosKey);
  }
}
