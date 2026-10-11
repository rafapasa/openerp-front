import 'package:front_openerp/core/helpers/json_helper.dart';
import 'package:front_openerp/data/models/models.dart';

import 'services.dart';

class DashboardService {
  final ApiService _apiService;

  DashboardService(this._apiService);

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _inRange(DateTime? created, DateTime inicio, DateTime fim) {
    if (created == null) return false;
    final day = _day(created.toLocal());
    return !day.isBefore(inicio) && !day.isAfter(fim);
  }

  Future<DashboardModel> getDashboard({DateTime? dataInicio, DateTime? dataFim}) async {
    final inicio = dataInicio != null ? _day(dataInicio) : _day(DateTime.now());
    final fim = dataFim != null ? _day(dataFim) : inicio;
    final query = <String, dynamic>{'data_inicio': _ymd(inicio), 'data_fim': _ymd(fim)};

    DashboardModel base;
    try {
      final response = await _apiService.get('/dashboard', queryParameters: query);
      final extracted = JsonHelper.extractData(response.data);
      final map = extracted is Map<String, dynamic>
          ? extracted
          : (response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : <String, dynamic>{});
      base = DashboardModel.fromJson(map);
    } catch (_) {
      base = DashboardModel(
        totalPedidosHoje: 0,
        totalPedidosSemana: 0,
        totalClientes: 0,
        pedidosPendentes: 0,
        pedidosPorStatus: const {},
        faturamentoHoje: 0,
        faturamentoMes: 0,
      );
    }

    final pedidosRes = await _apiService.get('/pedidos', queryParameters: {'page': 1, 'limit': 200, ...query});
    final lista = JsonHelper.extractList(pedidosRes.data);

    final status = <String, int>{};
    var faturamento = 0.0;
    var count = 0;
    for (final raw in lista) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final created = JsonHelper.toDateTime(item['created_at']);
      if (!_inRange(created, inicio, fim)) continue;
      count++;
      final st = '${item['status'] ?? 'pendente'}';
      status[st] = (status[st] ?? 0) + 1;
      final total = item['total'];
      if (total is num) faturamento += total.toDouble();
    }

    return base.copyWith(
      totalPedidosHoje: count,
      faturamentoHoje: faturamento,
      pedidosPendentes: status['pendente'] ?? 0,
      pedidosPorStatus: status,
    );
  }
}
