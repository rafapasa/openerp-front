import 'package:front_openerp/core/helpers/json_helper.dart';

class TenantNotificacaoModel {
  final int? id;
  final int? tenantId;
  final String canal;
  final String destino;
  final String evento;
  final bool ativo;

  TenantNotificacaoModel({
    this.id,
    this.tenantId,
    required this.canal,
    required this.destino,
    required this.evento,
    this.ativo = true,
  });

  factory TenantNotificacaoModel.fromJson(Map<String, dynamic> json) {
    return TenantNotificacaoModel(
      id: json['id'] != null ? JsonHelper.toInt(json['id']) : null,
      tenantId: json['tenant_id'] != null ? JsonHelper.toInt(json['tenant_id']) : null,
      canal: JsonHelper.toStr(json['canal'], fallback: 'whatsapp'),
      destino: JsonHelper.toStr(json['destino']),
      evento: JsonHelper.toStr(json['evento'], fallback: 'novo_pedido'),
      ativo: JsonHelper.toBool(json['ativo'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (tenantId != null) 'tenant_id': tenantId,
    'canal': canal,
    'destino': destino,
    'evento': evento,
    'ativo': ativo,
  };

  TenantNotificacaoModel copyWith({
    int? id,
    int? tenantId,
    String? canal,
    String? destino,
    String? evento,
    bool? ativo,
  }) {
    return TenantNotificacaoModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      canal: canal ?? this.canal,
      destino: destino ?? this.destino,
      evento: evento ?? this.evento,
      ativo: ativo ?? this.ativo,
    );
  }
}
