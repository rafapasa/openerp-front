import 'package:front_openerp/core/helpers/json_helper.dart';
import 'package:front_openerp/data/models/models.dart';

import 'services.dart';

class PedidoService {
  final ApiService _apiService;
  PedidoService(this._apiService);

  Future<PaginatedResponse<PedidoModel>> getPedidos({
    int page = 1,
    int limit = 20,
    String? status,
    int? clienteId,
    String? dataInicio,
    String? dataFim,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (clienteId != null) 'cliente_id': clienteId,
      if (dataInicio != null) 'data_inicio': dataInicio,
      if (dataFim != null) 'data_fim': dataFim,
    };
    final response = await _apiService.get('/pedidos', queryParameters: queryParams);
    return PaginatedResponse<PedidoModel>.fromJson(
      _comoMapa(response.data),
      (json) => PedidoModel.fromJson(_comoMapa(json)),
    );
  }

  Future<PedidoModel> getPedidoById(int id) async {
    final response = await _apiService.get('/pedidos/$id');
    return PedidoModel.fromJson(_mapPedido(response.data));
  }

  Future<PedidoModel> updateStatusPedido(int id, StatusPedido status, {String? motivo}) async {
    final body = <String, dynamic>{
      'status': status.toStringValue(),
      if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
    };
    final response = await _apiService.patch('/pedidos/$id/status', data: body);
    return PedidoModel.fromJson(_mapPedido(response.data));
  }

  Future<PedidoModel> marcarPago(int id, {int? formaPagamentoId, double? valor, String? observacao}) async {
    try {
      final response = await _apiService.patch(
        '/pedidos/$id/pagamento',
        data: {
          'pago': true,
          if (formaPagamentoId != null) 'forma_pagamento_id': formaPagamentoId,
          if (valor != null) 'valor': valor,
          if (observacao != null) 'observacao': observacao,
        },
      );
      final map = response.data as Map<String, dynamic>;
      final data = map['data'] as Map<String, dynamic>;
      return PedidoModel.fromJson(data);
    } catch (_) {
      rethrow;
    }
  }

  Future<PaginatedResponse<PedidoModel>> getPedidosByCliente(int clienteId, {int page = 1, int limit = 20}) async {
    final response = await _apiService.get(
      '/clientes/$clienteId/pedidos',
      queryParameters: {'page': page, 'limit': limit},
    );
    return PaginatedResponse<PedidoModel>.fromJson(
      _comoMapa(response.data),
      (json) => PedidoModel.fromJson(_comoMapa(json)),
    );
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
  }) async {
    final response = await _apiService.post(
      '/pedidos',
      data: {
        'cliente_id': clienteId,
        'cliente_nome': clienteNome,
        'cliente_telefone': clienteTelefone,
        'itens': itens,
        if (observacoes != null && observacoes.trim().isNotEmpty) 'observacoes': observacoes.trim(),
        if (enderecoEntregaId != null) 'endereco_entrega_id': enderecoEntregaId,
        'origem': origem,
        if (etiqueta != null && etiqueta.trim().isNotEmpty) 'etiqueta': etiqueta.trim(),
      },
    );
    final map = response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : <String, dynamic>{};
    final data = map['data'] is Map<String, dynamic> ? map['data'] as Map<String, dynamic> : map;
    return PedidoModel.fromJson(data);
  }
}

Map<String, dynamic> _mapPedido(dynamic raw) {
  final data = JsonHelper.extractData(raw);
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  throw Exception('Resposta de pedido invalida');
}

Map<String, dynamic> _comoMapa(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  throw Exception('Resposta de pedido invalida');
}
