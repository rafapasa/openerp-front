import 'package:flutter_test/flutter_test.dart';
import 'package:front_openerp/data/models/models.dart';

Map<String, dynamic> pedidoMinimoJson() => {
      'id': 128,
      'cliente_nome': 'João Silva',
      'cliente_telefone': '49999999999',
      'itens': [
        {'nome': 'X-Salada', 'quantidade': 2, 'preco': 25.9},
      ],
      'total': 51.8,
      'status': 'pendente',
      'origem': 'whatsapp',
      'created_at': '2026-09-10T00:50:00Z',
      'updated_at': '2026-09-10T00:50:00Z',
    };

Map<String, dynamic> pedidoWhatsAppJson() => {
      'id': 12,
      'cliente_nome': 'Rafael Pada',
      'cliente_telefone': '49999999999',
      'itens': [
        {
          'produto_item': {'id': 1, 'nome': 'X-Salada', 'preco': 25.9},
          'quantidade': 1,
          'preco_unitario': 25.9,
          'observacao': 'sem cebola',
        },
        {
          'produto_item': {'id': 2, 'nome': 'Coca 350ml'},
          'qtd': 2,
          'preco_unitario': 6.0,
        },
      ],
      'total': 37.9,
      'status': 'confirmado',
      'origem': 'whatsapp',
      'created_at': '2026-09-15T18:33:00Z',
      'updated_at': '2026-09-15T18:33:00Z',
    };

Map<String, dynamic> pedidoCompletoJson() => {
      ...pedidoMinimoJson(),
      'status': 'cancelado',
      'pago': true,
      'pago_em': '2026-09-10T01:20:00Z',
      'motivo_cancelamento': 'Cliente pediu para cancelar',
      'pagamentos': [
        {
          'id': 10,
          'forma_pagamento_id': 1,
          'forma': 'PIX',
          'valor': 51.8,
          'status': 'pago',
          'pago_em': '2026-09-10T01:20:00Z',
        },
      ],
      'historico': [
        {
          'id': 1,
          'status_anterior': null,
          'status_novo': 'pendente',
          'usuario_nome': 'sistema',
          'created_at': '2026-09-10T00:50:00Z',
        },
        {
          'id': 2,
          'status_anterior': 'pendente',
          'status_novo': 'cancelado',
          'motivo': 'Cliente pediu para cancelar',
          'usuario_nome': 'Rafael',
          'created_at': '2026-09-10T01:15:00Z',
        },
      ],
    };

void main() {
  group('PedidoModel.fromJson', () {
    test('pedido mínimo deixa campos novos nulos/vazios', () {
      final pedido = PedidoModel.fromJson(pedidoMinimoJson());

      expect(pedido.id, 128);
      expect(pedido.clienteNome, 'João Silva');
      expect(pedido.status, StatusPedido.pendente);
      expect(pedido.itens, hasLength(1));
      expect(pedido.itens.first.subtotal, closeTo(51.8, 0.001));

      expect(pedido.pagamentos, isEmpty);
      expect(pedido.historico, isEmpty);
      expect(pedido.pago, isNull);
      expect(pedido.pagoEm, isNull);
      expect(pedido.motivoCancelamento, isNull);
    });

    test('item no formato WhatsApp (produto_item + preco_unitario)', () {
      final pedido = PedidoModel.fromJson(pedidoWhatsAppJson());
      expect(pedido.itens, hasLength(2));
      expect(pedido.itens[0].nome, 'X-Salada');
      expect(pedido.itens[0].quantidade, 1);
      expect(pedido.itens[0].preco, closeTo(25.9, 0.001));
      expect(pedido.itens[0].observacao, 'sem cebola');
      expect(pedido.itens[1].nome, 'Coca 350ml');
      expect(pedido.itens[1].quantidade, 2);
      expect(pedido.itens[1].preco, closeTo(6.0, 0.001));
      expect(pedido.itens[1].subtotal, closeTo(12.0, 0.001));
    });

    test('pedido com pagamentos, historico e motivo_cancelamento', () {
      final pedido = PedidoModel.fromJson(pedidoCompletoJson());

      expect(pedido.status, StatusPedido.cancelado);
      expect(pedido.pago, isTrue);
      expect(pedido.motivoCancelamento, 'Cliente pediu para cancelar');
      expect(pedido.pagamentos, hasLength(1));
      expect(pedido.pagamentos.first.forma, 'PIX');
      expect(pedido.pagamentos.first.isPago, isTrue);
      expect(pedido.historico, hasLength(2));
      expect(pedido.historico.last.statusNovo, 'cancelado');
      expect(pedido.historico.last.motivo, 'Cliente pediu para cancelar');
    });
  });

  group('PedidoModel getters', () {
    test('totalFormatado', () {
      final pedido = PedidoModel.fromJson(pedidoMinimoJson());
      expect(pedido.totalFormatado, 'R\$ 51.80');
    });

    test('formaPagamentoResumo vazio e preenchido', () {
      expect(PedidoModel.fromJson(pedidoMinimoJson()).formaPagamentoResumo, '—');
      expect(PedidoModel.fromJson(pedidoCompletoJson()).formaPagamentoResumo, 'PIX');
    });

    test('isPago pelo flag e pelo pagamento aninhado', () {
      expect(PedidoModel.fromJson(pedidoMinimoJson()).isPago, isFalse);
      expect(PedidoModel.fromJson(pedidoCompletoJson()).isPago, isTrue);

      final soPagamento = PedidoModel.fromJson({
        ...pedidoMinimoJson(),
        'pagamentos': [
          {'forma': 'Dinheiro', 'valor': 51.8, 'status': 'pago'},
        ],
      });
      expect(soPagamento.pago, isNull);
      expect(soPagamento.isPago, isTrue);
    });

    test('podeCancelar e isAtivo por status', () {
      PedidoModel withStatus(String status) =>
          PedidoModel.fromJson({...pedidoMinimoJson(), 'status': status});

      expect(withStatus('pendente').podeCancelar, isTrue);
      expect(withStatus('confirmado').podeCancelar, isTrue);
      expect(withStatus('preparando').podeCancelar, isTrue);
      expect(withStatus('em_preparo').podeCancelar, isTrue);
      expect(withStatus('pronto').podeCancelar, isFalse);
      expect(withStatus('entregue').podeCancelar, isFalse);

      expect(withStatus('pendente').isAtivo, isTrue);
      expect(withStatus('entregue').isAtivo, isFalse);
      expect(withStatus('cancelado').isAtivo, isFalse);
    });
  });
}
