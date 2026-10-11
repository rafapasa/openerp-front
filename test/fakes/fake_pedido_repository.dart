import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/repositories/pedido_repository.dart';

class FakePedidoRepository implements PedidoRepository {
  final List<PedidoModel> store;
  StatusPedido? lastStatus;
  String? lastMotivo;
  int? lastId;

  FakePedidoRepository(this.store);

  @override
  Future<PaginatedResponse<PedidoModel>> getPedidos({
    int page = 1,
    int limit = 20,
    String? status,
    int? clienteId,
    String? dataInicio,
    String? dataFim,
    bool forceRefresh = false,
  }) async {
    return PaginatedResponse<PedidoModel>(
      data: List.of(store),
      total: store.length,
      page: page,
      limit: limit,
      pages: 1,
    );
  }

  @override
  Future<PedidoModel> getPedidoById(int id) async {
    return store.firstWhere((p) => p.id == id);
  }

  @override
  Future<PedidoModel> updateStatus(int id, StatusPedido status, {String? motivo}) async {
    lastId = id;
    lastStatus = status;
    lastMotivo = motivo;
    final index = store.indexWhere((p) => p.id == id);
    store[index] = store[index].copyWith(
      status: status,
      motivoCancelamento: motivo,
      updatedAt: DateTime.now(),
    );
    return store[index];
  }

  @override
  Future<PedidoModel> marcarPago(int id, {int? formaPagamentoId, double? valor, String? observacao}) async {
    final i = store.indexWhere((p) => p.id == id);
    store[i] = store[i].copyWith(pago: true, pagoEm: DateTime.now());
    return store[i];
  }

  @override
  Future<PedidoModel> createPedido({
    required int clienteId,
    required String clienteNome,
    String clienteTelefone = '',
    required List<Map<String, dynamic>> itens,
    String? observacoes,
    int? enderecoEntregaId,
    String origem = 'dashboard',
    String? etiqueta,
  }) async {
    final pedido = PedidoModel(
      id: store.isEmpty ? 1 : store.first.id + 100,
      clienteNome: clienteNome,
      clienteTelefone: clienteTelefone,
      itens: itens
          .map((e) => ItemPedidoModel(
                produtoId: e['produto_id'] as int?,
                nome: '${e['nome'] ?? ''}',
                quantidade: e['quantidade'] is int ? e['quantidade'] as int : 1,
                preco: (e['preco'] as num?)?.toDouble() ?? 0,
              ))
          .toList(),
      total: itens.fold<double>(0, (s, e) {
        final q = e['quantidade'] is int ? e['quantidade'] as int : 1;
        final p = (e['preco'] as num?)?.toDouble() ?? 0;
        return s + q * p;
      }),
      status: StatusPedido.pendente,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    store.insert(0, pedido);
    return pedido;
  }

  @override
  Future<void> clearCache() async {}
}
