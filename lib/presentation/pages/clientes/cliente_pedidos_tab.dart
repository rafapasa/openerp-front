import 'package:flutter/material.dart';
import 'package:front_openerp/core/helpers/json_helper.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/models/pedido_model.dart';
import 'package:front_openerp/data/services/api_service.dart';
import 'package:front_openerp/presentation/pages/pedidos/pedido_detalhe_modal.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';

class ClientePedidosTab extends StatefulWidget {
  final int clienteId;
  const ClientePedidosTab({super.key, required this.clienteId});

  @override
  State<ClientePedidosTab> createState() => _ClientePedidosTabState();
}

class _ClientePedidosTabState extends State<ClientePedidosTab> {
  final _scroll = ScrollController();
  final List<PedidoModel> _pedidos = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 100) {
      if (!_loadingMore && _hasMore) _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _pedidos.clear();
      _page = 1;
      _hasMore = true;
    });
    try {
      final api = context.read<ApiService>();
      final res = await api.get('/clientes/${widget.clienteId}/pedidos', queryParameters: {'page': 1, 'limit': 20});
      final list = JsonHelper.extractList(res.data);
      final itens = list.whereType<Map<String, dynamic>>().map(PedidoModel.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _pedidos.addAll(itens);
        _hasMore = itens.length >= 20;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final api = context.read<ApiService>();
      final res = await api.get('/clientes/${widget.clienteId}/pedidos', queryParameters: {'page': next, 'limit': 20});
      final list = JsonHelper.extractList(res.data);
      final itens = list.whereType<Map<String, dynamic>>().map(PedidoModel.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _pedidos.addAll(itens);
        _page = next;
        _hasMore = itens.length >= 20;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return Center(child: Text(_error!));
    if (_pedidos.isEmpty) {
      return const Center(child: Text('Nenhum pedido encontrado'));
    }
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final date = DateFormat('dd/MM/yyyy HH:mm');
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      itemCount: _pedidos.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        if (i == _pedidos.length) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final p = _pedidos[i];
        return InkWell(
          onTap: () => showPedidoDetalheModal(context, p.id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${p.id}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(date.format(p.createdAt), style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(int.parse(p.statusColor.replaceFirst('#', '0xff'))).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(int.parse(p.statusColor.replaceFirst('#', '0xff'))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(money.format(p.total), style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        );
      },
    );
  }
}
