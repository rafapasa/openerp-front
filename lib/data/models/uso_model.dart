import 'package:front_openerp/core/helpers/json_helper.dart';

class UsoModel {
  final int id;
  final int? tenantId;
  final String slug;
  final String label;
  final String sinonimos;
  final bool ativo;

  const UsoModel({
    required this.id,
    this.tenantId,
    required this.slug,
    required this.label,
    this.sinonimos = '',
    this.ativo = true,
  });

  factory UsoModel.fromJson(Map<String, dynamic> json) {
    return UsoModel(
      id: JsonHelper.toInt(json['id']),
      tenantId: json['tenant_id'] != null ? JsonHelper.toInt(json['tenant_id']) : null,
      slug: JsonHelper.toStr(json['slug']),
      label: JsonHelper.toStr(json['label']),
      sinonimos: JsonHelper.toStr(json['sinonimos']),
      ativo: JsonHelper.toBool(json['ativo'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'slug': slug,
    'label': label,
    'sinonimos': sinonimos,
    'ativo': ativo,
  };

  UsoModel copyWith({int? id, int? tenantId, String? slug, String? label, String? sinonimos, bool? ativo}) {
    return UsoModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      slug: slug ?? this.slug,
      label: label ?? this.label,
      sinonimos: sinonimos ?? this.sinonimos,
      ativo: ativo ?? this.ativo,
    );
  }
}
