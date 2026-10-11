// lib/presentation/pages/dashboard/dashboard_page.dart
// Refatorado eTools - Dashboard responsivo Web + Mobile
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:front_openerp/data/models/enums.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../pedidos/novo_pedido_modal.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final provider = context.read<DashboardProvider>();
      await provider.loadDashboard();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    final provider = context.read<DashboardProvider>();
    await provider.refreshDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final isWeb = MediaQuery.of(context).size.width > 800;

    if (_isLoading || provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (provider.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Erro ao carregar dados', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadData, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    if (provider.dashboard == null) {
      return const Scaffold(body: Center(child: Text('Nenhum dado disponível')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Dashboard Web
                  if (isWeb)
                    Row(
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Visão geral do seu negócio em tempo real',
                              style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _DateChip(
                          label: 'De',
                          value: provider.dataInicio,
                          onPick: (d) => provider.setPeriodo(d, provider.dataFim.isBefore(d) ? d : provider.dataFim),
                        ),
                        const SizedBox(width: 8),
                        _DateChip(
                          label: 'Até',
                          value: provider.dataFim,
                          onPick: (d) =>
                              provider.setPeriodo(provider.dataInicio.isAfter(d) ? d : provider.dataInicio, d),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _refreshData,
                          icon: const Icon(Icons.download_outlined, size: 18),
                          label: const Text('Exportar'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: () => showNovoPedidoModal(context),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Novo Pedido'),
                        ),
                      ],
                    ),
                  if (!isWeb) ...[
                    const Text(
                      'Dashboard',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DateChip(
                          label: 'De',
                          value: provider.dataInicio,
                          onPick: (d) => provider.setPeriodo(d, provider.dataFim.isBefore(d) ? d : provider.dataFim),
                        ),
                        _DateChip(
                          label: 'Até',
                          value: provider.dataFim,
                          onPick: (d) =>
                              provider.setPeriodo(provider.dataInicio.isAfter(d) ? d : provider.dataInicio, d),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isWeb) const SizedBox(height: 24),
                  _buildMetricCards(provider, isWeb),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, c) {
                      if (c.maxWidth > 900) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildStatusChart(provider)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildRevenueCard(provider)),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildStatusChart(provider),
                            const SizedBox(height: 16),
                            _buildRevenueCard(provider),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Footer eTools
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified, size: 14, color: AppColors.accent),
                        SizedBox(width: 6),
                        Text(
                          'Dados sincronizados com o backend',
                          style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildMetricCards(DashboardProvider provider, bool isWeb) {
  final numberFormat = NumberFormat.decimalPattern('pt_BR');

  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: isWeb ? 4 : 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    childAspectRatio: isWeb ? 1.7 : 1.45,
    children: [
      _MetricCard(
        title: 'Pedidos',
        value: provider.totalPedidosHoje.toString(),
        icon: Icons.shopping_cart_outlined,
        color: AppColors.primary,
      ),
      _MetricCard(
        title: 'Faturamento',
        value: 'R\$ ${numberFormat.format(provider.faturamentoHoje)}',
        icon: Icons.attach_money,
        color: AppColors.accent,
      ),
      _MetricCard(
        title: 'Clientes',
        value: provider.totalClientes.toString(),
        icon: Icons.people_outline,
        color: const Color(0xFF0EA5E9),
      ),
      _MetricCard(
        title: 'Pendentes',
        value: provider.pedidosPendentes.toString(),
        icon: Icons.pending_outlined,
        color: const Color(0xFFF59E0B),
      ),
      if (isWeb)
        _MetricCard(
          title: 'Faturamento Mês',
          value: 'R\$ ${numberFormat.format(provider.faturamentoMes)}',
          icon: Icons.trending_up,
          color: AppColors.primaryDark,
        ),
      if (isWeb)
        _MetricCard(
          title: 'Taxa Conversão',
          value: '${provider.taxaConversao.toStringAsFixed(1)}%',
          icon: Icons.percent,
          color: const Color(0xFF8B5CF6),
        ),
    ],
  );
}

Widget _buildStatusChart(DashboardProvider provider) {
  final statusData = provider.pedidosPorStatus;

  if (statusData.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Center(
        child: Text('Sem dados de pedidos por status', style: TextStyle(color: Colors.grey[600])),
      ),
    );
  }

  final colors = {
    'pendente': AppColors.warning,
    'confirmado': AppColors.primary,
    'preparando': const Color(0xFF8B5CF6),
    'em_preparo': const Color(0xFF8B5CF6),
    'saiu_para_entrega': const Color(0xFF0EA5E9),
    'saiu_entrega': const Color(0xFF0EA5E9),
    'entregue': AppColors.accent,
    'cancelado': AppColors.error,
  };

  final entries = statusData.entries.toList();
  final total = entries.fold(0, (sum, e) => sum + e.value);

  return Container(
    decoration: AppTheme.cardDecoration,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.pie_chart_outline, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            const Text('Pedidos por Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('Total: $total', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: entries.map((entry) {
                final status = StatusPedido.fromString(entry.key);
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: '${status.label}\n${entry.value}',
                  color: colors[entry.key] ?? Colors.grey,
                  radius: 60,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 32,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entries.map((entry) {
            final status = StatusPedido.fromString(entry.key);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (colors[entry.key] ?? Colors.grey).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${status.label}: ${entry.value}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors[entry.key] ?? Colors.grey),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

Widget _buildRevenueCard(DashboardProvider provider) {
  final numberFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  return Container(
    decoration: AppTheme.cardDecoration,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.accentLight, shape: BoxShape.circle),
              child: const Icon(Icons.attach_money, size: 18, color: AppColors.accent),
            ),
            const SizedBox(width: 10),
            const Text('Faturamento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _RevenueItem(
                label: 'Hoje',
                value: numberFormat.format(provider.faturamentoHoje),
                color: AppColors.accent,
              ),
            ),
            Expanded(
              child: _RevenueItem(
                label: 'Mês',
                value: numberFormat.format(provider.faturamentoMes),
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: provider.faturamentoMes > 0 ? (provider.faturamentoHoje / provider.faturamentoMes).clamp(0, 1) : 0,
            backgroundColor: AppColors.background,
            color: AppColors.accent,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text('Valores do intervalo selecionado', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;

  const _MetricCard({required this.title, required this.value, required this.icon, required this.color}) : trend = null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (trend != null) Icon(Icons.trending_up, size: 14, color: AppColors.accent),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              if (trend != null)
                Text(
                  trend!,
                  style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RevenueItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;

  const _DateChip({required this.label, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final text = DateFormat('dd/MM/yyyy').format(value);
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2024),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked != null) onPick(picked);
      },
      child: Text('$label $text'),
    );
  }
}
