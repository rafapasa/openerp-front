class CategoriaModel {
  final int id;
  final int tenantId;
  final String nome;
  final String tipo;
  final int ordem;
  final bool ativo;

  const CategoriaModel({
    required this.id,
    required this.tenantId,
    required this.nome,
    required this.tipo,
    required this.ordem,
    required this.ativo,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'] as int? ?? 0,
      tenantId: json['tenant_id'] as int? ?? 0,
      nome: json['nome'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'peca',
      ordem: json['ordem'] as int? ?? 0,
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  String get tipoLabel {
    switch (tipo) {
      case 'tinta':
        return 'Tinta';
      case 'pneu':
        return 'Pneu';
      case 'massa':
        return 'Massa';
      case 'outro':
        return 'Outro';
      default:
        return 'Peça';
    }
  }
}
