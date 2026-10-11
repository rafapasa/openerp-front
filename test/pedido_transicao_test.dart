import 'package:flutter_test/flutter_test.dart';
import 'package:front_openerp/data/models/models.dart';

import 'pedido_model_test.dart';

void main() {
  PedidoModel pedido({required String status, int? enderecoId}) {
    return PedidoModel.fromJson({
      ...pedidoMinimoJson(),
      'status': status,
      if (enderecoId != null) 'endereco_entrega_id': enderecoId,
    });
  }

  group('proximoOperacional', () {
    test('retirada em_preparo aponta prontoRetirada', () {
      final p = pedido(status: 'em_preparo');
      expect(p.isEntrega, isFalse);
      expect(p.proximoOperacional, StatusPedido.prontoRetirada);
      expect(p.proximoLabel, 'Pronto p/ retirar');
    });

    test('entrega em_preparo aponta saiuEntrega', () {
      final p = pedido(status: 'em_preparo', enderecoId: 3);
      expect(p.isEntrega, isTrue);
      expect(p.proximoOperacional, StatusPedido.saiuEntrega);
    });
  });

  group('pedidoPodeMoverPara', () {
    test('retirada nao cai em saiuEntrega', () {
      final p = pedido(status: 'em_preparo');
      expect(pedidoPodeMoverPara(p, StatusPedido.prontoRetirada), isTrue);
      expect(pedidoPodeMoverPara(p, StatusPedido.saiuEntrega), isFalse);
    });

    test('entrega nao cai em prontoRetirada', () {
      final p = pedido(status: 'em_preparo', enderecoId: 3);
      expect(pedidoPodeMoverPara(p, StatusPedido.saiuEntrega), isTrue);
      expect(pedidoPodeMoverPara(p, StatusPedido.prontoRetirada), isFalse);
    });

    test('confirmado nao pula para prontoRetirada', () {
      final p = pedido(status: 'confirmado');
      expect(pedidoPodeMoverPara(p, StatusPedido.prontoRetirada), isFalse);
      expect(pedidoPodeMoverPara(p, StatusPedido.emPreparo), isTrue);
    });
  });
}
