import 'package:openerp_front/core/helpers/json_helper.dart';

class EnderecoModel {
  final int id;
  final int? clienteId;
  final String cep;
  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final String pais;
  final String? referencia;
  final double? latitude;
  final double? longitude;
  final String tipo;
  final bool principal;
  final DateTime createdAt;
  final DateTime updatedAt;

  EnderecoModel({
    required this.id,
    this.clienteId,
    required this.cep,
    required this.logradouro,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.estado,
    this.pais = 'Brasil',
    this.referencia,
    this.latitude,
    this.longitude,
    this.tipo = 'residencial',
    this.principal = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EnderecoModel.fromJson(Map<String, dynamic> json) {
    return EnderecoModel(
      id: JsonHelper.toInt(json['id']),
      clienteId: json['cliente_id'] != null ? JsonHelper.toInt(json['cliente_id']) : null,
      cep: json['cep'] ?? '',
      logradouro: json['logradouro'] ?? '',
      numero: json['numero'] ?? '',
      complemento: json['complemento'],
      bairro: json['bairro'] ?? '',
      cidade: json['cidade'] ?? '',
      estado: json['estado'] ?? '',
      pais: json['pais'] ?? 'Brasil',
      referencia: json['referencia'],
      latitude: json['latitude'] != null ? JsonHelper.toDouble(json['latitude']) : null,
      longitude: json['longitude'] != null ? JsonHelper.toDouble(json['longitude']) : null,
      tipo: json['tipo'] ?? 'residencial',
      principal: json['principal'] ?? false,
      createdAt: JsonHelper.toDateTimeOrNow(json['created_at']),
      updatedAt: JsonHelper.toDateTimeOrNow(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cliente_id': clienteId,
    'cep': cep,
    'logradouro': logradouro,
    'numero': numero,
    'complemento': complemento,
    'bairro': bairro,
    'cidade': cidade,
    'estado': estado,
    'pais': pais,
    'referencia': referencia,
    'latitude': latitude,
    'longitude': longitude,
    'tipo': tipo,
    'principal': principal,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  String get enderecoCompleto =>
      '$logradouro, $numero${complemento != null ? ' - $complemento' : ''}, $bairro - $cidade/$estado';
}
