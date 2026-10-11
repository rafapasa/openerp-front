import 'package:flutter_test/flutter_test.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/services/pedido_service.dart';

import 'fakes/fake_api_service.dart';
import 'pedido_model_test.dart';

void main() {
  group('PedidoService.updateStatusPedido', () {
    test('PATCH envia só {status} quando não há motivo', () async {
      final api = FakeApiService(
        responseData: {
          'data': {...pedidoMinimoJson(), 'status': 'confirmado'},
        },
      );
      final service = PedidoService(api);

      final pedido = await service.updateStatusPedido(128, StatusPedido.confirmado);

      expect(api.lastMethod, 'PATCH');
      expect(api.lastPath, '/pedidos/128/status');
      expect(api.lastData, {'status': 'confirmado'});
      expect(pedido.status, StatusPedido.confirmado);
    });

    test('PATCH inclui motivo quando informado', () async {
      final api = FakeApiService(
        responseData: {
          'data': {
            ...pedidoMinimoJson(),
            'status': 'cancelado',
            'motivo_cancelamento': 'sem estoque',
          },
        },
      );
      final service = PedidoService(api);

      await service.updateStatusPedido(
        128,
        StatusPedido.cancelado,
        motivo: '  sem estoque  ',
      );

      expect(api.lastPath, '/pedidos/128/status');
      expect(api.lastData, {
        'status': 'cancelado',
        'motivo': 'sem estoque',
      });
    });

    test('motivo vazio ou só espaço não entra no body', () async {
      final api = FakeApiService(
        responseData: {
          'data': {...pedidoMinimoJson(), 'status': 'em_preparo'},
        },
      );
      final service = PedidoService(api);

      await service.updateStatusPedido(128, StatusPedido.emPreparo, motivo: '   ');

      expect(api.lastData, {'status': 'em_preparo'});
    });

    test('PATCH envia pronto_retirada e parseia envelope data', () async {
      final api = FakeApiService(
        responseData: {
          'data': {...pedidoMinimoJson(), 'status': 'pronto_retirada'},
        },
      );
      final service = PedidoService(api);
      final pedido = await service.updateStatusPedido(128, StatusPedido.prontoRetirada);
      expect(api.lastData, {'status': 'pronto_retirada'});
      expect(pedido.status, StatusPedido.prontoRetirada);
    });

    test('PATCH parseia pedido sem envelope data', () async {
      final api = FakeApiService(
        responseData: {...pedidoMinimoJson(), 'status': 'pronto_retirada'},
      );
      final service = PedidoService(api);
      final pedido = await service.updateStatusPedido(3, StatusPedido.prontoRetirada);
      expect(pedido.id, 128);
      expect(pedido.status, StatusPedido.prontoRetirada);
    });
  });
}
