import 'package:front_openerp/core/helpers/json_helper.dart';

import 'cliente_model.dart';
import 'endereco_model.dart';
import 'enums.dart';

class ItemPedidoModel {
  final int? produtoId;
  final String nome;
  final int quantidade;
  final double preco;
  final String? observacao;

  ItemPedidoModel({this.produtoId, required this.nome, required this.quantidade, required this.preco, this.observacao});

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = JsonHelper.toStr(value).trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  factory ItemPedidoModel.fromJson(Map<String, dynamic> json) {
    final produtoItem = json['produto_item'] is Map
        ? Map<String, dynamic>.from(json['produto_item'] as Map)
        : const <String, dynamic>{};

    return ItemPedidoModel(
      produtoId: (json['produto_id'] ?? produtoItem['id']) != null
          ? JsonHelper.toInt(json['produto_id'] ?? produtoItem['id'])
          : null,
      nome: _firstNonEmpty([json['nome'], produtoItem['nome'], json['produto_nome'], produtoItem['descricao']]),
      quantidade: JsonHelper.toInt(json['quantidade'] ?? json['qtd']),
      preco: JsonHelper.toDouble(json['preco'] ?? json['preco_unitario'] ?? produtoItem['preco']),
      observacao: (json['observacao'] ?? json['obs']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'produto_id': produtoId,
    'nome': nome,
    'quantidade': quantidade,
    'preco': preco,
    'observacao': observacao,
  };

  double get subtotal => quantidade * preco;
}

class PagamentoPedidoModel {
  final int? id;
  final int? formaPagamentoId;
  final String forma;
  final double valor;
  final String status;
  final DateTime? pagoEm;

  PagamentoPedidoModel({
    this.id,
    this.formaPagamentoId,
    required this.forma,
    required this.valor,
    this.status = 'pendente',
    this.pagoEm,
  });

  factory PagamentoPedidoModel.fromJson(Map<String, dynamic> json) {
    return PagamentoPedidoModel(
      id: json['id'] != null ? JsonHelper.toInt(json['id']) : null,
      formaPagamentoId: json['forma_pagamento_id'] != null ? JsonHelper.toInt(json['forma_pagamento_id']) : null,
      forma: JsonHelper.toStr(json['forma'], fallback: JsonHelper.toStr(json['nome'], fallback: '—')),
      valor: JsonHelper.toDouble(json['valor']),
      status: JsonHelper.toStr(json['status'], fallback: 'pendente'),
      pagoEm: json['pago_em'] != null ? JsonHelper.toDateTimeOrNow(json['pago_em']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'forma_pagamento_id': formaPagamentoId,
    'forma': forma,
    'valor': valor,
    'status': status,
    'pago_em': pagoEm?.toIso8601String(),
  };

  bool get isPago => status.toLowerCase() == 'pago' || status.toLowerCase() == 'confirmado';
}

class HistoricoPedidoModel {
  final int? id;
  final String? statusAnterior;
  final String statusNovo;
  final String? motivo;
  final int? usuarioId;
  final String? usuarioNome;
  final DateTime createdAt;

  HistoricoPedidoModel({
    this.id,
    this.statusAnterior,
    required this.statusNovo,
    this.motivo,
    this.usuarioId,
    this.usuarioNome,
    required this.createdAt,
  });

  factory HistoricoPedidoModel.fromJson(Map<String, dynamic> json) {
    return HistoricoPedidoModel(
      id: json['id'] != null ? JsonHelper.toInt(json['id']) : null,
      statusAnterior: json['status_anterior'] as String?,
      statusNovo: JsonHelper.toStr(json['status_novo'], fallback: JsonHelper.toStr(json['status'])),
      motivo: json['motivo'] as String?,
      usuarioId: json['usuario_id'] != null ? JsonHelper.toInt(json['usuario_id']) : null,
      usuarioNome: json['usuario_nome'] as String?,
      createdAt: JsonHelper.toDateTimeOrNow(json['created_at']),
    );
  }
}

class PedidoModel {
  final int id;
  final int? tenantId;
  final int? clienteId;
  final String clienteNome;
  final String clienteTelefone;
  final int? enderecoEntregaId;
  final EnderecoModel? enderecoEntrega;
  final List<ItemPedidoModel> itens;
  final double total;
  final StatusPedido status;
  final String? observacoes;
  final int? tempoEstimado;
  final OrigemPedido origem;
  final String? etiqueta;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ClienteModel? cliente;
  final List<PagamentoPedidoModel> pagamentos;
  final bool? pago;
  final DateTime? pagoEm;
  final String? motivoCancelamento;
  final List<HistoricoPedidoModel> historico;

  PedidoModel({
    required this.id,
    this.tenantId,
    this.clienteId,
    required this.clienteNome,
    required this.clienteTelefone,
    this.enderecoEntregaId,
    this.enderecoEntrega,
    required this.itens,
    required this.total,
    required this.status,
    this.observacoes,
    this.tempoEstimado,
    this.origem = OrigemPedido.whatsapp,
    this.etiqueta,
    required this.createdAt,
    required this.updatedAt,
    this.cliente,
    this.pagamentos = const [],
    this.pago,
    this.pagoEm,
    this.motivoCancelamento,
    this.historico = const [],
  });

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    return PedidoModel(
      id: JsonHelper.toInt(json['id']),
      tenantId: json['tenant_id'] != null ? JsonHelper.toInt(json['tenant_id']) : null,
      clienteId: json['cliente_id'] != null ? JsonHelper.toInt(json['cliente_id']) : null,
      clienteNome: JsonHelper.toStr(json['cliente_nome']),
      clienteTelefone: JsonHelper.toStr(json['cliente_telefone']),
      enderecoEntregaId: json['endereco_entrega_id'] != null ? JsonHelper.toInt(json['endereco_entrega_id']) : null,
      enderecoEntrega: json['endereco_entrega'] != null
          ? EnderecoModel.fromJson(json['endereco_entrega'] as Map<String, dynamic>)
          : null,
      itens: JsonHelper.toList(json['itens'], (e) => ItemPedidoModel.fromJson(e as Map<String, dynamic>)),
      total: JsonHelper.toDouble(json['total']),
      status: StatusPedido.fromString(JsonHelper.toStr(json['status'], fallback: 'pendente')),
      observacoes: json['observacoes'] as String?,
      tempoEstimado: json['tempo_estimado'] != null ? JsonHelper.toInt(json['tempo_estimado']) : null,
      origem: OrigemPedido.fromString(JsonHelper.toStr(json['origem'], fallback: 'whatsapp')),
      etiqueta: JsonHelper.toStr(json['etiqueta']),
      createdAt: JsonHelper.toDateTimeOrNow(json['created_at']),
      updatedAt: JsonHelper.toDateTimeOrNow(json['updated_at']),
      cliente: json['cliente'] != null ? ClienteModel.fromJson(json['cliente'] as Map<String, dynamic>) : null,
      pagamentos: JsonHelper.toList(
        json['pagamentos'],
        (e) => PagamentoPedidoModel.fromJson(e as Map<String, dynamic>),
      ),
      pago: json['pago'] as bool?,
      pagoEm: json['pago_em'] != null ? JsonHelper.toDateTimeOrNow(json['pago_em']) : null,
      motivoCancelamento: (json['motivo_cancelamento'] ?? json['motivo']) as String?,
      historico: JsonHelper.toList(json['historico'], (e) => HistoricoPedidoModel.fromJson(e as Map<String, dynamic>)),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'cliente_id': clienteId,
    'cliente_nome': clienteNome,
    'cliente_telefone': clienteTelefone,
    'endereco_entrega_id': enderecoEntregaId,
    'endereco_entrega': enderecoEntrega?.toJson(),
    'itens': itens.map((e) => e.toJson()).toList(),
    'total': total,
    'status': status.toStringValue(),
    'observacoes': observacoes,
    'tempo_estimado': tempoEstimado,
    'origem': origem.toStringValue(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'pagamentos': pagamentos.map((e) => e.toJson()).toList(),
    'pago': pago,
    'pago_em': pagoEm?.toIso8601String(),
    'motivo_cancelamento': motivoCancelamento,
  };

  PedidoModel copyWith({
    StatusPedido? status,
    bool? pago,
    DateTime? pagoEm,
    String? motivoCancelamento,
    List<PagamentoPedidoModel>? pagamentos,
    List<HistoricoPedidoModel>? historico,
    DateTime? updatedAt,
  }) {
    return PedidoModel(
      id: id,
      tenantId: tenantId,
      clienteId: clienteId,
      clienteNome: clienteNome,
      clienteTelefone: clienteTelefone,
      enderecoEntregaId: enderecoEntregaId,
      enderecoEntrega: enderecoEntrega,
      itens: itens,
      total: total,
      status: status ?? this.status,
      observacoes: observacoes,
      tempoEstimado: tempoEstimado,
      origem: origem,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cliente: cliente,
      pagamentos: pagamentos ?? this.pagamentos,
      pago: pago ?? this.pago,
      pagoEm: pagoEm ?? this.pagoEm,
      motivoCancelamento: motivoCancelamento ?? this.motivoCancelamento,
      historico: historico ?? this.historico,
    );
  }

  String get statusLabel => status.label;
  String get statusColor => status.colorHex;
  String get statusIcon => status.iconName;
  String get origemLabel => origem.label;
  String get totalFormatado => 'R\$ ${total.toStringAsFixed(2)}';
  bool get podeCancelar =>
      status == StatusPedido.pendente || status == StatusPedido.confirmado || status == StatusPedido.emPreparo;
  bool get isAtivo => status != StatusPedido.entregue && status != StatusPedido.cancelado;
  bool get isPago => pago == true || pagamentos.any((p) => p.isPago);
  bool get isEntrega => enderecoEntregaId != null || enderecoEntrega != null;

  StatusPedido? get proximoOperacional {
    switch (status) {
      case StatusPedido.pendente:
        return StatusPedido.confirmado;
      case StatusPedido.confirmado:
        return StatusPedido.emPreparo;
      case StatusPedido.emPreparo:
        return isEntrega ? StatusPedido.saiuEntrega : StatusPedido.prontoRetirada;
      case StatusPedido.prontoRetirada:
      case StatusPedido.saiuEntrega:
        return StatusPedido.entregue;
      default:
        return null;
    }
  }

  String get proximoLabel {
    switch (proximoOperacional) {
      case StatusPedido.confirmado:
        return 'Confirmar';
      case StatusPedido.emPreparo:
        return 'Preparar';
      case StatusPedido.saiuEntrega:
        return 'Saiu p/ entrega';
      case StatusPedido.prontoRetirada:
        return 'Pronto p/ retirar';
      case StatusPedido.entregue:
        return isEntrega ? 'Entregar' : 'Retirado';
      default:
        return '';
    }
  }

  String get formaPagamentoResumo {
    if (pagamentos.isEmpty) return '—';
    return pagamentos.map((p) => p.forma).join(', ');
  }
}
