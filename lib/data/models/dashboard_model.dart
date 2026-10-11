import 'package:flutter/foundation.dart';

class DashboardModel {
  final int totalPedidosHoje;
  final int totalPedidosSemana;
  final int totalClientes;
  final int pedidosPendentes;
  final Map<String, int> pedidosPorStatus;
  final double faturamentoHoje;
  final double faturamentoMes;

  DashboardModel({
    required this.totalPedidosHoje,
    required this.totalPedidosSemana,
    required this.totalClientes,
    required this.pedidosPendentes,
    required this.pedidosPorStatus,
    required this.faturamentoHoje,
    required this.faturamentoMes,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final hoje = json['hoje'] is Map ? Map<String, dynamic>.from(json['hoje'] as Map) : <String, dynamic>{};
    final statusRaw = json['status'] ?? json['pedidos_por_status'] ?? {};
    final status = <String, int>{};
    if (statusRaw is Map) {
      statusRaw.forEach((key, value) {
        status[key.toString()] = value is int ? value : int.tryParse('$value') ?? 0;
      });
    }

    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    double asDouble(dynamic v) {
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0;
    }

    if (kDebugMode) {
      print('DashboardModel.fromJson: $json');
    }

    return DashboardModel(
      totalPedidosHoje: asInt(hoje['pedidos'] ?? json['total_pedidos_hoje']),
      totalPedidosSemana: asInt(json['total_pedidos_semana']),
      totalClientes: asInt(json['total_clientes']),
      pedidosPendentes: asInt(status['pendente'] ?? json['pedidos_pendentes']),
      pedidosPorStatus: status,
      faturamentoHoje: asDouble(hoje['faturamento'] ?? json['faturamento_hoje']),
      faturamentoMes: asDouble(json['faturamento_mes']),
    );
  }

  DashboardModel copyWith({
    int? totalPedidosHoje,
    int? totalPedidosSemana,
    int? totalClientes,
    int? pedidosPendentes,
    Map<String, int>? pedidosPorStatus,
    double? faturamentoHoje,
    double? faturamentoMes,
  }) {
    return DashboardModel(
      totalPedidosHoje: totalPedidosHoje ?? this.totalPedidosHoje,
      totalPedidosSemana: totalPedidosSemana ?? this.totalPedidosSemana,
      totalClientes: totalClientes ?? this.totalClientes,
      pedidosPendentes: pedidosPendentes ?? this.pedidosPendentes,
      pedidosPorStatus: pedidosPorStatus ?? this.pedidosPorStatus,
      faturamentoHoje: faturamentoHoje ?? this.faturamentoHoje,
      faturamentoMes: faturamentoMes ?? this.faturamentoMes,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_pedidos_hoje': totalPedidosHoje,
    'total_pedidos_semana': totalPedidosSemana,
    'total_clientes': totalClientes,
    'pedidos_pendentes': pedidosPendentes,
    'pedidos_por_status': pedidosPorStatus,
    'hoje': {'pedidos': totalPedidosHoje, 'faturamento': faturamentoHoje},
    'status': pedidosPorStatus,
    'faturamento_hoje': faturamentoHoje,
    'faturamento_mes': faturamentoMes,
  };
}
