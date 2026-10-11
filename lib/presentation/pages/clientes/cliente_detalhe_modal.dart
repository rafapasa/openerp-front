import 'package:flutter/material.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import 'cliente_dados_tab.dart';
import 'cliente_pedidos_tab.dart';

Future<void> showClienteDetalheModal(BuildContext context, int clienteId) {
  final isWide = MediaQuery.of(context).size.width >= 720;
  if (isWide) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
          child: ClienteDetalheModal(clienteId: clienteId),
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
      child: ClienteDetalheModal(clienteId: clienteId),
    ),
  );
}

class ClienteDetalheModal extends StatefulWidget {
  final int clienteId;
  const ClienteDetalheModal({super.key, required this.clienteId});

  @override
  State<ClienteDetalheModal> createState() => _ClienteDetalheModalState();
}

class _ClienteDetalheModalState extends State<ClienteDetalheModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ClienteModel? _cliente;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final provider = context.read<ClienteProvider>();
    final fetched = await provider.getClienteById(widget.clienteId);
    if (!mounted) return;
    setState(() {
      _cliente = fetched;
      _loading = false;
      if (_cliente == null) _error = provider.error ?? 'Cliente nao encontrado';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          _header(),
          if (_cliente != null)
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textGrey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Dados'),
                Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Pedidos'),
              ],
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                ? Center(child: Text(_error!))
                : _cliente == null
                ? const Center(child: Text('Cliente nao encontrado'))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      ClienteDadosTab(cliente: _cliente!, onSaved: _load),
                      ClientePedidosTab(clienteId: widget.clienteId),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final c = _cliente;
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
                Text(
                  c?.nome ?? 'Cliente #${widget.clienteId}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                if (c != null) Text(c.telefone, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          if (c != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.status == 'ativo' ? AppColors.successBg : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                c.status == 'ativo' ? 'Ativo' : 'Inativo',
                style: TextStyle(
                  color: c.status == 'ativo' ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}
