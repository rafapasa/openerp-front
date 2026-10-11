// lib/presentation/providers/dashboard_provider.dart
import 'package:flutter/material.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/repositories/repositories.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _dashboardRepository;

  DashboardModel? _dashboard;
  bool _isLoading = false;
  String? _error;
  bool _isRefreshing = false;
  DateTime _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _dataFim = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  DashboardModel? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  DateTime get dataInicio => _dataInicio;
  DateTime get dataFim => _dataFim;

  int get totalPedidosHoje => _dashboard?.totalPedidosHoje ?? 0;
  int get totalPedidosSemana => _dashboard?.totalPedidosSemana ?? 0;
  int get totalClientes => _dashboard?.totalClientes ?? 0;
  int get pedidosPendentes => _dashboard?.pedidosPendentes ?? 0;
  double get faturamentoHoje => _dashboard?.faturamentoHoje ?? 0;
  double get faturamentoMes => _dashboard?.faturamentoMes ?? 0;
  Map<String, int> get pedidosPorStatus => _dashboard?.pedidosPorStatus ?? {};

  double get taxaConversao {
    final total = pedidosPorStatus.values.fold(0, (sum, value) => sum + value);
    if (total == 0) return 0;
    final entregues = pedidosPorStatus[StatusPedido.entregue.toStringValue()] ?? 0;
    return (entregues / total) * 100;
  }

  DashboardProvider(this._dashboardRepository);

  Future<void> setPeriodo(DateTime inicio, DateTime fim) async {
    _dataInicio = DateTime(inicio.year, inicio.month, inicio.day);
    _dataFim = DateTime(fim.year, fim.month, fim.day);
    await loadDashboard(forceRefresh: true);
  }

  Future<void> loadDashboard({bool forceRefresh = false}) async {
    if (!forceRefresh && _dashboard != null) return;

    _setLoading(true);
    try {
      _dashboard = await _dashboardRepository.getDashboard(
        forceRefresh: forceRefresh,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
      );
      _clearError();
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> refreshDashboard() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      _dashboard = await _dashboardRepository.refreshDashboard(dataInicio: _dataInicio, dataFim: _dataFim);
      _clearError();
    } catch (e) {
      _error = e.toString();
    }
    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> clearCache() async {
    await _dashboardRepository.clearCache();
    _dashboard = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
