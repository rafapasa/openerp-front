import 'package:openerp_front/core/helpers/json_helper.dart';

/// Origens possíveis de um token de produto.
/// - nome: palavra que já está no nome do produto (default)
/// - abrev: abreviação ou nome completo gerado a partir dela
/// - ano: ano expandido (93/00 -> 1993..2000)
/// - uso: token vindo do uso (ex.: gripe, resfriado)
enum ProdutoTokenOrigem {
  nome,
  modelo,
  abrev,
  ano,
  uso;

  static const ProdutoTokenOrigem fallback = ProdutoTokenOrigem.nome;

  static ProdutoTokenOrigem fromValue(dynamic value) {
    final raw = JsonHelper.toStr(value).trim().toLowerCase();
    for (final o in ProdutoTokenOrigem.values) {
      if (o.name == raw) return o;
    }
    return fallback;
  }

  String get label {
    switch (this) {
      case ProdutoTokenOrigem.nome:
        return 'Nome';
      case ProdutoTokenOrigem.modelo:
        return 'Modelo';
      case ProdutoTokenOrigem.abrev:
        return 'Abrev';
      case ProdutoTokenOrigem.ano:
        return 'Ano';
      case ProdutoTokenOrigem.uso:
        return 'Uso';
    }
  }
}

class ProdutoTokenModel {
  final int id;
  final int produtoId;
  final String token;
  final ProdutoTokenOrigem origem;

  const ProdutoTokenModel({
    required this.id,
    required this.produtoId,
    required this.token,
    this.origem = ProdutoTokenOrigem.nome,
  });

  factory ProdutoTokenModel.fromJson(Map<String, dynamic> json) {
    return ProdutoTokenModel(
      id: JsonHelper.toInt(json['id']),
      produtoId: JsonHelper.toInt(json['produto_id']),
      token: JsonHelper.toStr(json['token']),
      origem: ProdutoTokenOrigem.fromValue(json['origem']),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'produto_id': produtoId, 'token': token, 'origem': origem.name};

  /// Payload de criação (POST): sem id.
  Map<String, dynamic> toCreateJson() => {'token': token, 'origem': origem.name};

  /// Payload de atualização (PUT): com id.
  Map<String, dynamic> toUpdateJson() => {'id': id, 'token': token, 'origem': origem.name};

  ProdutoTokenModel copyWith({int? id, int? produtoId, String? token, ProdutoTokenOrigem? origem}) {
    return ProdutoTokenModel(
      id: id ?? this.id,
      produtoId: produtoId ?? this.produtoId,
      token: token ?? this.token,
      origem: origem ?? this.origem,
    );
  }
}
