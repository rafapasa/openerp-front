import 'package:flutter_test/flutter_test.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/presentation/providers/pedido_provider.dart';

import 'fakes/fake_pedido_repository.dart';
import 'pedido_model_test.dart';

void main() {
  group('PedidoProvider.updateStatus', () {
    test('atualiza a lista local e dispara notifyListeners', () async {
      final pedido = PedidoModel.fromJson(pedidoMinimoJson());
      final repo = FakePedidoRepository([pedido]);
      final provider = PedidoProvider(repo);

      await provider.loadPedidos();
      expect(provider.pedidos.single.status, StatusPedido.pendente);

      var notifications = 0;
      provider.addListener(() => notifications++);

      final ok = await provider.updateStatus(
        128,
        StatusPedido.emPreparo,
        motivo: null,
      );

      expect(ok, isTrue);
      expect(repo.lastId, 128);
      expect(repo.lastStatus, StatusPedido.emPreparo);
      expect(provider.pedidos.single.status, StatusPedido.emPreparo);
      expect(notifications, greaterThan(0));
    });

    test('encaminha motivo para o repository', () async {
      final pedido = PedidoModel.fromJson(pedidoMinimoJson());
      final repo = FakePedidoRepository([pedido]);
      final provider = PedidoProvider(repo);
      await provider.loadPedidos();

      final ok = await provider.updateStatus(
        128,
        StatusPedido.cancelado,
        motivo: 'cliente desistiu',
      );

      expect(ok, isTrue);
      expect(repo.lastMotivo, 'cliente desistiu');
      expect(provider.pedidos.single.status, StatusPedido.cancelado);
    });
  });
}
