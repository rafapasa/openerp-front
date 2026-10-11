// lib/presentation/pages/pedidos/detalhe_pedido_page.dart
// Refatorado eTools - Responsivo
import 'package:flutter/material.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class DetalhePedidoPage extends StatefulWidget {
  final int pedidoId;
  const DetalhePedidoPage({super.key, required this.pedidoId});

  @override
  State<DetalhePedidoPage> createState() => _DetalhePedidoPageState();
}

class _DetalhePedidoPageState extends State<DetalhePedidoPage> {
  PedidoModel? _pedido;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPedido());
  }

  Future<void> _loadPedido() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final provider = context.read<PedidoProvider>();
      final pedido = await provider.getPedidoById(widget.pedidoId);
      if (!mounted) return;
      setState(() {
        _pedido = pedido;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(StatusPedido novoStatus) async {
    final provider = context.read<PedidoProvider>();
    final success = await provider.updateStatus(widget.pedidoId, novoStatus);
    if (!mounted) return;
    if (success) {
      await _loadPedido();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status atualizado para ${novoStatus.label}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Erro ao atualizar status'), backgroundColor: AppColors.error),
      );
    }
  }

  IconData _getStatusIcon(StatusPedido status) {
    switch (status) {
      case StatusPedido.pendente:
        return Icons.pending_outlined;
      case StatusPedido.confirmado:
        return Icons.check_circle_outline;
      case StatusPedido.entregue:
        return Icons.delivery_dining_outlined;
      case StatusPedido.cancelado:
        return Icons.cancel_outlined;
      case StatusPedido.emPreparo:
        return Icons.production_quantity_limits_outlined;
      case StatusPedido.prontoRetirada:
        return Icons.assignment_turned_in_outlined;
      case StatusPedido.saiuEntrega:
        return Icons.delivery_dining;
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Pedido #${widget.pedidoId}', style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (_pedido != null && _pedido!.podeCancelar)
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
              onPressed: () => _updateStatus(StatusPedido.cancelado),
              tooltip: 'Cancelar pedido',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Erro ao carregar pedido', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _loadPedido, child: const Text('Tentar novamente')),
                ],
              ),
            )
          : _pedido == null
          ? const Center(child: Text('Pedido não encontrado'))
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWeb ? 900 : double.infinity),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isWeb ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status
                      Container(
                        decoration: AppTheme.cardDecoration,
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Color(int.parse(_pedido!.statusColor.replaceFirst('#', '0xff')))
                                    .withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getStatusIcon(_pedido!.status),
                                color: Color(int.parse(_pedido!.statusColor.replaceFirst('#', '0xff'))),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pedido!.statusLabel,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Status atual do pedido',
                                    style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (_pedido!.isAtivo)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButton<StatusPedido>(
                                  value: _pedido!.status,
                                  underline: const SizedBox(),
                                  items: StatusPedido.values
                                      .map(
                                        (status) => DropdownMenuItem(
                                          value: status,
                                          child: Text(status.label, style: const TextStyle(fontSize: 13)),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (newStatus) {
                                    if (newStatus != null) _updateStatus(newStatus);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, c) {
                          final wide = c.maxWidth > 700;
                          final clienteCard = Container(
                            decoration: AppTheme.cardDecoration,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text('Cliente', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _pedido!.clienteNome,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                if (_pedido!.enderecoEntrega != null) ...[
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Endereço de Entrega',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _pedido!.enderecoEntrega!.enderecoCompleto,
                                    style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          );

                          final itensCard = Container(
                            decoration: AppTheme.cardDecoration,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentLight,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.accent),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text('Itens', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ..._pedido!.itens.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 3, child: Text(item.nome, style: const TextStyle(fontSize: 13))),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            '${item.quantidade}x',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            numberFormat.format(item.subtotal),
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                    Text(
                                      numberFormat.format(_pedido!.total),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );

                          if (wide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: clienteCard),
                                const SizedBox(width: 16),
                                Expanded(child: itensCard),
                              ],
                            );
                          } else {
                            return Column(children: [clienteCard, const SizedBox(height: 16), itensCard]);
                          }
                        },
                      ),
                      if (_pedido!.observacoes != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: AppTheme.cardDecoration,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.notes_outlined, size: 18, color: AppColors.warning),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text('Observações', style: TextStyle(fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _pedido!.observacoes!,
                                style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: AppColors.textGrey),
                                const SizedBox(width: 8),
                                Text(
                                  'Criado em: ${dateFormat.format(_pedido!.createdAt)}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.update, size: 14, color: AppColors.textGrey),
                                const SizedBox(width: 8),
                                Text(
                                  'Atualizado em: ${dateFormat.format(_pedido!.updatedAt)}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.source_outlined, size: 14, color: AppColors.textGrey),
                                const SizedBox(width: 8),
                                Text(
                                  'Origem: ${_pedido!.origemLabel}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                                ),
                              ],
                            ),
                            if (_pedido!.tempoEstimado != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 14, color: AppColors.textGrey),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tempo estimado: ${_pedido!.tempoEstimado} min',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
