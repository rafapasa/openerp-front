import 'package:flutter/material.dart';
import 'package:front_openerp/presentation/widgets/viewport_box.dart';
import 'package:front_openerp/core/helpers/launch_url.dart';
import 'package:front_openerp/core/helpers/snack_helper.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:front_openerp/presentation/theme/app_colors.dart';
import 'package:front_openerp/presentation/widgets/app_section_card.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:front_openerp/presentation/pages/pedidos/pagamento_pedido_dialog.dart';

Future<void> showPedidoDetalheModal(BuildContext context, int pedidoId) {
  final isWide = MediaQuery.of(context).size.width >= 720;
  if (isWide) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: caixaDaJanela(context, maxWidth: 640),
          child: PedidoDetalheModal(pedidoId: pedidoId),
        ),
      ),
    );
  }
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.92,
      child: PedidoDetalheModal(pedidoId: pedidoId),
    ),
  );
}

class PedidoDetalheModal extends StatefulWidget {
  final int pedidoId;
  const PedidoDetalheModal({super.key, required this.pedidoId});

  @override
  State<PedidoDetalheModal> createState() => _PedidoDetalheModalState();
}

class _PedidoDetalheModalState extends State<PedidoDetalheModal> {
  PedidoModel? _pedido;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final provider = context.read<PedidoProvider>();
    final local = provider.pedidos.where((p) => p.id == widget.pedidoId);
    if (local.isNotEmpty) {
      setState(() {
        _pedido = local.first;
        _loading = false;
      });
    }
    final fetched = await provider.getPedidoById(widget.pedidoId);
    if (!mounted) return;
    setState(() {
      _pedido = fetched ?? _pedido;
      _loading = false;
      if (_pedido == null) _error = provider.error ?? 'Pedido não encontrado';
    });
  }

  Future<void> _changeStatus(StatusPedido status, {String? motivo}) async {
    if (_busy || _pedido == null) return;
    setState(() => _busy = true);
    final ok = await context.read<PedidoProvider>().updateStatus(_pedido!.id, status);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      final updated = context.read<PedidoProvider>().pedidos.where((p) => p.id == _pedido!.id);
      setState(() {
        _pedido = (updated.isNotEmpty ? updated.first : _pedido!).copyWith(
          status: status,
          motivoCancelamento: motivo ?? _pedido!.motivoCancelamento,
          updatedAt: DateTime.now(),
        );
      });
      showSavedSnack(context, message: 'Status atualizado');
    } else {
      showSavedSnack(context, message: 'Não foi possível atualizar');
    }
  }

  Future<void> _recusar() async {
    final controller = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recusar pedido'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Motivo (obrigatório)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
    if (motivo == null || motivo.isEmpty) return;
    await _changeStatus(StatusPedido.cancelado, motivo: motivo);
  }

  Future<void> _marcarPago() async {
    if (_pedido == null || _busy) return;
    setState(() => _busy = true);
    final ok = await showPagamentoPedidoDialog(context, _pedido!);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      final atual = context.read<PedidoProvider>().pedidos.where((x) => x.id == _pedido!.id);
      if (atual.isNotEmpty) setState(() => _pedido = atual.first);
    }
  }

  void _ligar() {
    final tel = _digits(_pedido?.clienteTelefone ?? '');
    if (tel.isEmpty) return;
    openExternalUrl('tel:+$tel');
  }

  void _whatsapp() {
    final tel = _digits(_pedido?.clienteTelefone ?? '');
    if (tel.isEmpty) return;
    openExternalUrl('https://wa.me/$tel');
  }

  void _maps() {
    final end = _pedido?.enderecoEntrega?.enderecoCompleto;
    if (end == null || end.isEmpty) return;
    openExternalUrl('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(end)}');
  }

  void _printCupom() {
    final p = _pedido;
    if (p == null) return;
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final itens = p.itens.map((i) => '<div>${i.quantidade}x ${i.nome} ${money.format(i.subtotal)}</div>').join();
    printHtml('''
<!doctype html><html><head><meta charset="utf-8">
<title>Cupom #${p.id}</title>
<style>
@page { size: 80mm auto; margin: 4mm; }
body { font-family: monospace; font-size: 12px; width: 72mm; }
h1 { font-size: 14px; text-align: center; }
hr { border: none; border-top: 1px dashed #000; }
</style></head><body>
<h1>Pedido #${p.id}</h1>
<div>${p.clienteNome}</div>
<div>${p.clienteTelefone}</div>
<div>${p.enderecoEntrega?.enderecoCompleto ?? ''}</div>
<hr>$itens<hr>
<div><b>TOTAL ${money.format(p.total)}</b></div>
<div>${p.formaPagamentoResumo} · ${p.isPago ? 'PAGO' : 'PENDENTE'}</div>
<div>${p.origemLabel} · ${p.statusLabel}</div>
</body></html>
''');
  }

  String _digits(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

  Color _statusColor(PedidoModel p) => Color(int.parse(p.statusColor.replaceFirst('#', '0xff')));

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          _header(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                ? Center(child: Text(_error!))
                : _body(),
          ),
          if (!_loading && _error == null && _pedido != null) _footerAcoes(_pedido!),
        ],
      ),
    );
  }

  Widget _header() {
    final p = _pedido;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedido #${widget.pedidoId}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                if (p != null)
                  Text(
                    '${p.totalFormatado} · ${p.origemLabel}',
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (p != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(p).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                p.statusLabel,
                style: TextStyle(color: _statusColor(p), fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  Widget _card({required String titulo, required Widget child}) {
    return AppSectionCard(titulo: titulo, child: child);
  }

  Widget _sideBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 108,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          side: BorderSide(color: color.withValues(alpha: 0.35)),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _body() {
    final p = _pedido!;
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final date = DateFormat('dd/MM HH:mm');
    final e = p.enderecoEntrega;
    final linhaEndereco = e == null
        ? (p.isEntrega ? 'Endereço não informado' : 'Retirada no local')
        : '${e.logradouro}, ${e.numero}${e.complemento != null && e.complemento!.isNotEmpty ? ' — ${e.complemento}' : ''}';
    final linhaCidade = e == null ? '' : '${e.cidade} / ${e.estado}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      children: [
        _card(
          titulo: 'Cliente',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.clienteNome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                    const SizedBox(height: 6),
                    Text(linhaEndereco, style: const TextStyle(fontSize: 15)),
                    if (linhaCidade.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(linhaCidade, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                    ],
                    if (p.etiqueta != null && p.etiqueta!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(p.etiqueta!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  _sideBtn(Icons.call, 'Ligar', AppColors.primary, _ligar),
                  const SizedBox(height: 6),
                  _sideBtn(Icons.chat, 'WhatsApp', const Color(0xFF25D366), _whatsapp),
                  const SizedBox(height: 6),
                  _sideBtn(Icons.map_outlined, 'Maps', const Color(0xFFEA4335), _maps),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _card(
          titulo: 'Itens',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...p.itens.map(
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${i.quantidade}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${i.nome}${i.observacao != null && i.observacao!.isNotEmpty ? ' (${i.observacao})' : ''}',
                        ),
                      ),
                      Text(money.format(i.subtotal), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              if (p.observacoes != null && p.observacoes!.isNotEmpty)
                Text('Obs.: ${p.observacoes}', style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: Text(p.totalFormatado, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _card(
          titulo: 'Pagamento',
          child: Row(
            children: [
              Icon(
                p.isPago ? Icons.check_circle : Icons.schedule,
                size: 36,
                color: p.isPago ? Colors.green : const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.isPago ? 'PAGO' : 'EM ABERTO',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: p.isPago ? Colors.green : const Color(0xFFF59E0B),
                      ),
                    ),
                    Text(p.formaPagamentoResumo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (!p.isPago) _sideBtn(Icons.payments_outlined, 'Receber', AppColors.accent, _marcarPago),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _card(
          titulo: 'Timeline',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.historico.isEmpty) ...[
                Text('Criado ${date.format(p.createdAt)}', style: const TextStyle(fontSize: 13)),
                Text('Atualizado ${date.format(p.updatedAt)} · ${p.statusLabel}', style: const TextStyle(fontSize: 13)),
                if (p.motivoCancelamento != null)
                  Text('Motivo: ${p.motivoCancelamento}', style: const TextStyle(fontSize: 13)),
              ] else
                ...p.historico.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${date.format(h.createdAt)}  ${h.statusNovo}${h.usuarioNome != null ? ' (${h.usuarioNome})' : ''}${h.motivo != null ? ' — ${h.motivo}' : ''}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _sideBtn(Icons.receipt_long, 'Cupom', AppColors.primary, _printCupom),
              ),
            ],
          ),
        ),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
      ],
    );
  }

  Widget _footerAcoes(PedidoModel p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (p.proximoOperacional != null) ...[
            FilledButton(
              onPressed: _busy ? null : () => _changeStatus(p.proximoOperacional!),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: Text(p.proximoLabel),
            ),
            const SizedBox(width: 8),
          ],
          if (p.isAtivo)
            OutlinedButton(
              onPressed: _busy ? null : _recusar,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Cancelar'),
            ),
        ],
      ),
    );
  }
}
