import 'package:front_openerp/core/helpers/json_helper.dart';

import 'endereco_model.dart';

class ClienteModel {
  final int id;
  final int? tenantId;
  final String telefone;
  final String nome;
  final String? nomePerfil;
  final String? email;
  final String? inscricaoFederal;
  final String status;
  final DateTime? ultimoPedidoAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<EnderecoModel>? enderecos;

  ClienteModel({
    required this.id,
    this.tenantId,
    required this.telefone,
    required this.nome,
    this.nomePerfil,
    this.email,
    this.inscricaoFederal,
    this.status = 'ativo',
    this.ultimoPedidoAt,
    required this.createdAt,
    required this.updatedAt,
    this.enderecos,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      id: json['id'],
      tenantId: json['tenant_id'],
      telefone: json['telefone'] ?? '',
      nome: json['nome'] ?? '',
      nomePerfil: json['nome_perfil'],
      email: json['email'],
      inscricaoFederal: json['inscricao_federal'],
      status: json['status'] ?? 'ativo',
      ultimoPedidoAt: json['ultimo_pedido_at'] != null ? JsonHelper.toDateTime(json['ultimo_pedido_at']) : null,
      createdAt: JsonHelper.toDateTimeOrNow(json['created_at']),
      updatedAt: JsonHelper.toDateTimeOrNow(json['updated_at']),
      enderecos: json['enderecos'] != null
          ? (json['enderecos'] as List).map((e) => EnderecoModel.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'telefone': telefone,
    'nome': nome,
    'nome_perfil': nomePerfil,
    'email': email,
    'inscricao_federal': inscricaoFederal,
    'status': status,
    'ultimo_pedido_at': ultimoPedidoAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'enderecos': enderecos?.map((e) => e.toJson()).toList(),
  };

  ClienteModel copyWith({
    int? id,
    int? tenantId,
    String? telefone,
    String? nome,
    String? nomePerfil,
    String? email,
    String? inscricaoFederal,
    String? status,
    DateTime? ultimoPedidoAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<EnderecoModel>? enderecos,
  }) {
    return ClienteModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      telefone: telefone ?? this.telefone,
      nome: nome ?? this.nome,
      nomePerfil: nomePerfil ?? this.nomePerfil,
      email: email ?? this.email,
      inscricaoFederal: inscricaoFederal ?? this.inscricaoFederal,
      status: status ?? this.status,
      ultimoPedidoAt: ultimoPedidoAt ?? this.ultimoPedidoAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      enderecos: enderecos ?? this.enderecos,
    );
  }
}
