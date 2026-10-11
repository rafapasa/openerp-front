import 'package:flutter_test/flutter_test.dart';
import 'package:front_openerp/data/models/tenant_llm_config.dart';

void main() {
  test('fromJson preenche prompts e regras', () {
    final cfg = TenantLlmConfig.fromJson({
      'segmento': 'eletrica',
      'prompts': {'video_sintese': 'liste cabos'},
      'regras': {'unidade_area': 'm2', 'margem_quantidade': 1.2},
    });
    expect(cfg.segmento, 'eletrica');
    expect(cfg.videoSintese, 'liste cabos');
    expect(cfg.unidadeArea, 'm2');
    expect(cfg.margemQuantidade, 1.2);
    expect(cfg.isEmpty, isFalse);
  });

  test('toApiJson vazio vira null', () {
    expect(const TenantLlmConfig().toApiJson(), isNull);
  });

  test('toApiJson so envia chaves preenchidas', () {
    final json = const TenantLlmConfig(
      segmento: 'obra',
      videoFrame: 'meça a sala',
    ).toApiJson();
    expect(json!['segmento'], 'obra');
    expect(json['prompts'], {'video_frame': 'meça a sala'});
    expect(json.containsKey('regras'), isFalse);
  });
}
