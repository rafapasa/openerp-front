// lib/presentation/providers/pedido_provider.dart
import 'package:flutter/material.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/repositories/repositories.dart';

class PedidoProvider extends ChangeNotifier {
  final PedidoRepository _pedidoRepository;

  // ============================================================
  // 📊 Estado
  // ============================================================
  List<PedidoModel> _pedidos = [];
  PaginatedResponse<PedidoModel>? _paginatedResponse;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // Filtros
  String? _statusFilter;
  int? _clienteFilter;
  String? _dataInicioFilter;
  String? _dataFimFilter;

  // ============================================================
  // 🔍 Getters
  // ============================================================
  List<PedidoModel> get pedidos => _pedidos;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  int get total => _paginatedResponse?.total ?? 0;
  int get currentPage => _currentPage;
  int get totalPages => _paginatedResponse?.pages ?? 0;

  String? get statusFilter => _statusFilter;
  int? get clienteFilter => _clienteFilter;
  String? get dataInicioFilter => _dataInicioFilter;
  String? get dataFimFilter => _dataFimFilter;

  // ============================================================
  // 📊 Pedidos por Status (para gráficos)
  // ============================================================
  Map<StatusPedido, List<PedidoModel>> get pedidosAgrupadosPorStatus {
    return {
      StatusPedido.pendente: _pedidos.where((p) => p.status == StatusPedido.pendente).toList(),
      StatusPedido.confirmado: _pedidos.where((p) => p.status == StatusPedido.confirmado).toList(),
      StatusPedido.emPreparo: _pedidos.where((p) => p.status == StatusPedido.emPreparo).toList(),
      StatusPedido.prontoRetirada: _pedidos.where((p) => p.status == StatusPedido.prontoRetirada).toList(),
      StatusPedido.saiuEntrega: _pedidos.where((p) => p.status == StatusPedido.saiuEntrega).toList(),
      StatusPedido.entregue: _pedidos.where((p) => p.status == StatusPedido.entregue).toList(),
      StatusPedido.cancelado: _pedidos.where((p) => p.status == StatusPedido.cancelado).toList(),
    };
  }

  // ============================================================
  // 🏗️ Construtor
  // ============================================================
  PedidoProvider(this._pedidoRepository);

  // ============================================================
  // 📋 Carregar Pedidos
  // ============================================================
  Future<void> loadPedidos({
    bool forceRefresh = false,
    String? status,
    int? clienteId,
    String? dataInicio,
    String? dataFim,
  }) async {
    // Atualizar filtros
    _statusFilter = status;
    _clienteFilter = clienteId;
    _dataInicioFilter = dataInicio;
    _dataFimFilter = dataFim;

    // Resetar paginação
    _currentPage = 1;
    _pedidos = [];
    _hasMore = true;

    _setLoading(true);

    try {
      final response = await _pedidoRepository.getPedidos(
        page: _currentPage,
        limit: 20,
        status: _statusFilter,
        clienteId: _clienteFilter,
        dataInicio: _dataInicioFilter,
        dataFim: _dataFimFilter,
        forceRefresh: forceRefresh,
      );

      _paginatedResponse = response;
      _pedidos = response.data;
      _hasMore = response.page < response.pages;
      _clearError();
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  // ============================================================
  // 📥 Carregar Mais (Pagination)
  // ============================================================
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _pedidoRepository.getPedidos(
        page: nextPage,
        limit: 20,
        status: _statusFilter,
        clienteId: _clienteFilter,
        dataInicio: _dataInicioFilter,
        dataFim: _dataFimFilter,
      );

      _paginatedResponse = response;
      _pedidos.addAll(response.data);
      _currentPage = nextPage;
      _hasMore = response.page < response.pages;
      _clearError();
    } catch (e) {
      _error = e.toString();
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  // ============================================================
  // 🔍 Buscar Pedido por ID
  // ============================================================
  Future<PedidoModel?> getPedidoById(int id) async {
    try {
      // Tentar encontrar no cache primeiro
      try {
        final cached = _pedidos.firstWhere((p) => p.id == id);
        return cached;
      } catch (e) {
        // Não encontrado, buscar da API
        final pedido = await _pedidoRepository.getPedidoById(id);
        // Adicionar à lista se não existir
        if (!_pedidos.any((p) => p.id == id)) {
          _pedidos.insert(0, pedido);
          notifyListeners();
        }
        return pedido;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ============================================================
  // 📝 Atualizar Status
  // ============================================================
  Future<bool> updateStatus(int id, StatusPedido novoStatus, {String? motivo}) async {
    try {
      final pedidoAtualizado = await _pedidoRepository.updateStatus(id, novoStatus, motivo: motivo);

      // Atualizar na lista
      final index = _pedidos.indexWhere((p) => p.id == id);
      if (index != -1) {
        _pedidos[index] = pedidoAtualizado;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // 🔄 Refresh
  // ============================================================
  Future<bool> marcarPago(int id, {int? formaPagamentoId, double? valor}) async {
    try {
      final atualizado = await _pedidoRepository.marcarPago(id, formaPagamentoId: formaPagamentoId, valor: valor);
      final index = _pedidos.indexWhere((p) => p.id == id);
      if (index != -1) _pedidos[index] = atualizado;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<PedidoModel?> createPedido({
    required int clienteId,
    required String clienteNome,
    String clienteTelefone = '',
    required List<Map<String, dynamic>> itens,
    String? observacoes,
    int? enderecoEntregaId,
    String origem = 'dashboard',
    String? etiqueta,
  }) async {
    try {
      final criado = await _pedidoRepository.createPedido(
        clienteId: clienteId,
        clienteNome: clienteNome,
        clienteTelefone: clienteTelefone,
        itens: itens,
        observacoes: observacoes,
        enderecoEntregaId: enderecoEntregaId,
        origem: origem,
        etiqueta: etiqueta,
      );
      _pedidos = [criado, ..._pedidos];
      notifyListeners();
      return criado;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> refreshPedidos() async {
    await loadPedidos(
      forceRefresh: true,
      status: _statusFilter,
      clienteId: _clienteFilter,
      dataInicio: _dataInicioFilter,
      dataFim: _dataFimFilter,
    );
  }

  // ============================================================
  // 🗑️ Limpar Filtros
  // ============================================================
  Future<void> clearFilters() async {
    _statusFilter = null;
    _clienteFilter = null;
    _dataInicioFilter = null;
    _dataFimFilter = null;
    await loadPedidos(forceRefresh: true);
  }

  // ============================================================
  // 🗑️ Limpar Cache
  // ============================================================
  Future<void> clearCache() async {
    await _pedidoRepository.clearCache();
    _pedidos = [];
    _paginatedResponse = null;
    notifyListeners();
  }

  // ============================================================
  // 🛠️ Métodos Privados
  // ============================================================
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
