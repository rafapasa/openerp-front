import 'package:front_openerp/core/helpers/json_helper.dart';
import 'package:front_openerp/data/models/uso_model.dart';

class ProdutoModel {
  final int id;
  final int? tenantId;
  final int? categoriaId;
  final String? categoriaNome;
  final String nome;
  final String? descricao;
  final double preco;
  final bool disponivel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<int> usoIds;
  final List<UsoModel> usos;

  ProdutoModel({
    required this.id,
    this.tenantId,
    this.categoriaId,
    this.categoriaNome,
    required this.nome,
    this.descricao,
    required this.preco,
    this.disponivel = true,
    required this.createdAt,
    required this.updatedAt,
    this.usoIds = const [],
    this.usos = const [],
  });

  factory ProdutoModel.fromJson(Map<String, dynamic> json) {
    return ProdutoModel(
      id: JsonHelper.toInt(json['id']),
      tenantId: json['tenant_id'] != null ? JsonHelper.toInt(json['tenant_id']) : null,
      categoriaId: json['categoria_id'] != null ? JsonHelper.toInt(json['categoria_id']) : null,
      categoriaNome: json['categoria_nome'],
      nome: JsonHelper.toStr(json['nome']),
      descricao: json['descricao'],
      preco: JsonHelper.toDouble(json['preco']),
      disponivel: JsonHelper.toBool(json['disponivel'], fallback: true),
      createdAt: JsonHelper.toDateTimeOrNow(json['created_at']),
      updatedAt: JsonHelper.toDateTimeOrNow(json['updated_at']),
      usoIds: _parseUsoIds(json),
      usos: _parseUsos(json['usos']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'categoria_id': categoriaId,
    'categoria_nome': categoriaNome,
    'nome': nome,
    'descricao': descricao,
    'preco': preco,
    'disponivel': disponivel,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'uso_ids': usoIds,
    'usos': usos.map((e) => e.toJson()).toList(),
  };

  ProdutoModel copyWith({
    int? id,
    int? tenantId,
    int? categoriaId,
    String? categoriaNome,
    String? nome,
    String? descricao,
    double? preco,
    bool? disponivel,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<int>? usoIds,
    List<UsoModel>? usos,
  }) {
    return ProdutoModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNome: categoriaNome ?? this.categoriaNome,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      preco: preco ?? this.preco,
      disponivel: disponivel ?? this.disponivel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      usoIds: usoIds ?? this.usoIds,
      usos: usos ?? this.usos,
    );
  }

  String get precoFormatado => 'R\$ ${preco.toStringAsFixed(2)}';
}

List<int> _parseUsoIds(Map<String, dynamic> json) {
  final raw = json['uso_ids'];
  if (raw is List) {
    return raw.map((e) => JsonHelper.toInt(e)).where((e) => e > 0).toList();
  }
  return _parseUsos(json['usos']).map((e) => e.id).toList();
}

List<UsoModel> _parseUsos(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((e) => UsoModel.fromJson(Map<String, dynamic>.from(e))).toList();
}
