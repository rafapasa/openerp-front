import 'package:flutter_test/flutter_test.dart';
import 'package:front_openerp/data/models/models.dart';

void main() {
  group('StatusPedido.fromString', () {
    test('mapeia status canônicos da API', () {
      expect(StatusPedido.fromString('pendente'), StatusPedido.pendente);
      expect(StatusPedido.fromString('confirmado'), StatusPedido.confirmado);
      expect(StatusPedido.fromString('em_preparo'), StatusPedido.emPreparo);
      expect(StatusPedido.fromString('pronto'), StatusPedido.prontoRetirada);
      expect(StatusPedido.fromString('pronto_retirada'), StatusPedido.prontoRetirada);
      expect(StatusPedido.fromString('saiu_para_entrega'), StatusPedido.saiuEntrega);
      expect(StatusPedido.fromString('entregue'), StatusPedido.entregue);
      expect(StatusPedido.fromString('cancelado'), StatusPedido.cancelado);
    });

    test('aceita enum legado preparando', () {
      expect(StatusPedido.fromString('preparando'), StatusPedido.emPreparo);
    });

    test('é case-insensitive e aceita aliases de entrega/preparo', () {
      expect(StatusPedido.fromString('EM_PREPARO'), StatusPedido.emPreparo);
      expect(StatusPedido.fromString('em-preparo'), StatusPedido.emPreparo);
      expect(StatusPedido.fromString('saiu-entrega'), StatusPedido.saiuEntrega);
      expect(StatusPedido.fromString('saiu_para_entrega'), StatusPedido.saiuEntrega);
    });

    test('valor desconhecido cai em pendente', () {
      expect(StatusPedido.fromString(''), StatusPedido.pendente);
      expect(StatusPedido.fromString('foo'), StatusPedido.pendente);
    });
  });

  group('StatusPedido.toStringValue', () {
    test('emite o contrato da API (snake_case, não camelCase)', () {
      expect(StatusPedido.emPreparo.toStringValue(), 'em_preparo');
      expect(StatusPedido.saiuEntrega.toStringValue(), 'saiu_para_entrega');
      expect(StatusPedido.prontoRetirada.toStringValue(), 'pronto_retirada');
      expect(StatusPedido.pendente.toStringValue(), 'pendente');
    });

    test('round-trip fromString(toStringValue)', () {
      for (final status in StatusPedido.values) {
        expect(StatusPedido.fromString(status.toStringValue()), status);
      }
    });
  });
}
