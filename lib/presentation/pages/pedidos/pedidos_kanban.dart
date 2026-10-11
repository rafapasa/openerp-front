// lib/presentation/pages/pedidos/pedidos_kanban.dart
import 'package:flutter/material.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/presentation/pages/pedidos/pagamento_pedido_dialog.dart';
import 'package:front_openerp/presentation/pages/pedidos/pedido_detalhe_modal.dart';
import 'package:front_openerp/presentation/providers/pedido_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';

const _colunas = <StatusPedido>[
  StatusPedido.pendente,
  StatusPedido.confirmado,
  StatusPedido.emPreparo,
  StatusPedido.prontoRetirada,
  StatusPedido.saiuEntrega,
  StatusPedido.entregue,
];

bool _naColuna(PedidoModel p, StatusPedido col) => p.status == col;
bool _aceitaDrop(PedidoModel p, StatusPedido dest) => pedidoPodeMoverPara(p, dest);

class PedidosKanban extends StatelessWidget {
  final List<PedidoModel> pedidos;
  const PedidosKanban({super.key, required this.pedidos});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = _colunas.length;
        final gap = 8.0;
        final livre = constraints.maxWidth.isFinite ? constraints.maxWidth : 1200.0;
        final larguraColuna = (livre - gap * (n - 1)) / n;
        final colunas = [
          for (var i = 0; i < n; i++)
            _Coluna(
              status: _colunas[i],
              colunaLargura: larguraColuna,
              pedidos: pedidos.where((p) => _naColuna(p, _colunas[i])).toList(),
            ),
        ];
        final quadro = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < colunas.length; i++) ...[if (i > 0) SizedBox(width: gap), Expanded(child: colunas[i])],
          ],
        );
        return SizedBox(
          width: constraints.maxWidth.isFinite ? constraints.maxWidth : null,
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
          child: quadro,
        );
      },
    );
  }
}

class _Coluna extends StatelessWidget {
  final StatusPedido status;
  final List<PedidoModel> pedidos;
  final double colunaLargura;
  const _Coluna({required this.status, required this.pedidos, required this.colunaLargura});

  Future<void> _receber(BuildContext context, PedidoModel pedido) async {
    if (!_aceitaDrop(pedido, status)) return;

    final pedidoProvider = context.read<PedidoProvider>();
    String? motivo;
    if (status == StatusPedido.cancelado) {
      final ctrl = TextEditingController();
      motivo = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancelar pedido'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Motivo'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Voltar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Cancelar pedido')),
          ],
        ),
      );
      if (motivo == null) return;
    }

    final ok = await pedidoProvider.updateStatus(pedido.id, status, motivo: motivo);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(pedidoProvider.error ?? 'Nao foi possivel mover o pedido')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<PedidoModel>(
      onWillAcceptWithDetails: (d) => _aceitaDrop(d.data, status),
      onAcceptWithDetails: (d) => _receber(context, d.data),
      builder: (context, candidate, rejected) {
        final overOk = candidate.isNotEmpty;
        final blocked = rejected.isNotEmpty && !overOk;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: blocked
                ? const Color(0xFFE8EAED)
                : overOk
                ? AppColors.accent.withValues(alpha: 0.08)
                : const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: overOk ? AppColors.accent : AppColors.border, width: overOk ? 2 : 1),
          ),
          child: Opacity(
            opacity: blocked ? 0.45 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          status.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                      Text(
                        '${pedidos.length}',
                        style: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                    itemCount: pedidos.isEmpty ? 1 : pedidos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      if (pedidos.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Solte aqui',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textGrey, fontSize: 11),
                          ),
                        );
                      }
                      return _CardKanban(pedido: pedidos[i], colunaLargura: colunaLargura);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CardKanban extends StatelessWidget {
  final PedidoModel pedido;
  final double colunaLargura;
  const _CardKanban({required this.pedido, required this.colunaLargura});

  Widget _corpo(BuildContext context, {required bool dragging}) {
    final money = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final next = pedido.proximoOperacional;
    final entrega = pedido.enderecoEntregaId != null || pedido.enderecoEntrega != null;
    return Material(
      elevation: dragging ? 8 : 0,
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: dragging ? null : () => showPedidoDetalheModal(context, pedido.id),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.drag_indicator, size: 14, color: AppColors.textGrey),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      '#${pedido.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      money.format(pedido.total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                (pedido.etiqueta != null && pedido.etiqueta!.trim().isNotEmpty) ? pedido.etiqueta! : pedido.clienteNome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: (pedido.etiqueta != null && pedido.etiqueta!.trim().isNotEmpty)
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _chip(entrega ? 'Entrega' : 'Retirada', AppColors.primary),
                  _chip(pedido.isPago ? 'Pago' : 'Em aberto', pedido.isPago ? Colors.green : const Color(0xFFF59E0B)),
                ],
              ),
              if (!dragging) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (!pedido.isPago && pedido.status != StatusPedido.cancelado)
                      Flexible(
                        child: TextButton(
                          onPressed: () => showPagamentoPedidoDialog(context, pedido),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Pago', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    if (next != null)
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: FilledButton(
                              onPressed: () async {
                                final ok = await context.read<PedidoProvider>().updateStatus(pedido.id, next);
                                if (!context.mounted || ok) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.read<PedidoProvider>().error ?? 'Nao foi possivel atualizar'),
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(pedido.proximoLabel, maxLines: 1),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = colunaLargura * 0.92;
    return Draggable<PedidoModel>(
      data: pedido,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: SizedBox(width: w, child: _corpo(context, dragging: true)),
      childWhenDragging: Opacity(opacity: 0.35, child: _corpo(context, dragging: false)),
      child: _corpo(context, dragging: false),
    );
  }

  Widget _chip(String t, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(
        t,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}
