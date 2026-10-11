class TenantLlmConfig {
  final String? segmento;
  final String? videoFrame;
  final String? videoSintese;
  final String? visaoLista;
  final String? transcribe;
  final String? unidadeArea;
  final double? margemQuantidade;

  const TenantLlmConfig({
    this.segmento,
    this.videoFrame,
    this.videoSintese,
    this.visaoLista,
    this.transcribe,
    this.unidadeArea,
    this.margemQuantidade,
  });

  bool get isEmpty =>
      _blank(segmento) &&
      _blank(videoFrame) &&
      _blank(videoSintese) &&
      _blank(visaoLista) &&
      _blank(transcribe) &&
      _blank(unidadeArea) &&
      margemQuantidade == null;

  factory TenantLlmConfig.fromJson(dynamic raw) {
    if (raw is! Map) return const TenantLlmConfig();
    final map = Map<String, dynamic>.from(raw);
    final prompts = map['prompts'] is Map ? Map<String, dynamic>.from(map['prompts'] as Map) : <String, dynamic>{};
    final regras = map['regras'] is Map ? Map<String, dynamic>.from(map['regras'] as Map) : <String, dynamic>{};
    return TenantLlmConfig(
      segmento: _str(map['segmento']),
      videoFrame: _str(prompts['video_frame']),
      videoSintese: _str(prompts['video_sintese']),
      visaoLista: _str(prompts['visao_lista']),
      transcribe: _str(prompts['transcribe']),
      unidadeArea: _str(regras['unidade_area']),
      margemQuantidade: _num(regras['margem_quantidade']),
    );
  }

  /// null = limpar no back (volta ao default).
  Map<String, dynamic>? toApiJson() {
    if (isEmpty) return null;
    final prompts = <String, String>{};
    if (!_blank(videoFrame)) prompts['video_frame'] = videoFrame!.trim();
    if (!_blank(videoSintese)) prompts['video_sintese'] = videoSintese!.trim();
    if (!_blank(visaoLista)) prompts['visao_lista'] = visaoLista!.trim();
    if (!_blank(transcribe)) prompts['transcribe'] = transcribe!.trim();
    final regras = <String, dynamic>{};
    if (!_blank(unidadeArea)) regras['unidade_area'] = unidadeArea!.trim();
    if (margemQuantidade != null) regras['margem_quantidade'] = margemQuantidade;
    return {
      if (!_blank(segmento)) 'segmento': segmento!.trim(),
      if (prompts.isNotEmpty) 'prompts': prompts,
      if (regras.isNotEmpty) 'regras': regras,
    };
  }

  static bool _blank(String? v) => v == null || v.trim().isEmpty;

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }
}
