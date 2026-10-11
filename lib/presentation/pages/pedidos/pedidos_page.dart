// lib/presentation/pages/pedidos/pedidos_page.dart
// Refatorado eTools - Responsivo
import 'package:flutter/material.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/presentation/pages/pedidos/novo_pedido_modal.dart';
import 'package:front_openerp/presentation/pages/pedidos/pedido_detalhe_modal.dart';
import 'package:front_openerp/presentation/pages/pedidos/pedidos_kanban.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _busca = TextEditingController();
  bool _quadro = true;

  String? _statusFilter;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _busca.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<PedidoProvider>().loadPedidos();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      final provider = context.read<PedidoProvider>();
      if (!provider.isLoadingMore && provider.hasMore) {
        provider.loadMore();
      }
    }
  }

  Future<void> _refreshData() async {
    await context.read<PedidoProvider>().refreshPedidos();
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _applyFilters() async {
    await context.read<PedidoProvider>().loadPedidos(
      status: _statusFilter,
      dataInicio: _formatDate(_dataInicio),
      dataFim: _formatDate(_dataFim),
    );
  }

  Future<void> _clearFilters() async {
    setState(() {
      _statusFilter = null;
      _dataInicio = null;
      _dataFim = null;
    });
    await context.read<PedidoProvider>().loadPedidos();
  }

  Future<void> _pickDate({required bool isInicio}) async {
    if (!mounted) return;
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5);
    final lastDate = DateTime(now.year + 1, 12, 31);
    final rawInitial = isInicio ? (_dataInicio ?? now.subtract(const Duration(days: 30))) : (_dataFim ?? now);
    final initial = rawInitial.isBefore(firstDate)
        ? firstDate
        : rawInitial.isAfter(lastDate)
        ? lastDate
        : rawInitial;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      useRootNavigator: true,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isInicio) {
        _dataInicio = picked;
        if (_dataFim != null && _dataFim!.isBefore(picked)) {
          _dataFim = picked;
        }
      } else {
        _dataFim = picked;
        if (_dataInicio != null && _dataInicio!.isAfter(picked)) {
          _dataInicio = picked;
        }
      }
    });
    await _applyFilters();
  }

  bool get _hasActiveFilters => _statusFilter != null || _dataInicio != null || _dataFim != null;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PedidoProvider>();
    final isWeb = MediaQuery.of(context).size.width > 800;
    final filtrados = _filtrados(provider.pedidos);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildToolbar(provider, isWeb, filtrados),
            if (_hasActiveFilters) _buildActiveFiltersBar(),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : provider.error != null
                  ? _buildError(provider.error!, context)
                  : provider.pedidos.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _refreshData,
                      child: _quadro
                          ? PedidosKanban(pedidos: filtrados)
                          : (isWeb ? _buildWebTable(provider, filtrados) : _buildMobileList(filtrados)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(PedidoProvider provider, bool isWeb, List<PedidoModel> filtrados) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 16 : 12),
      decoration: isWeb ? AppTheme.cardDecoration : const BoxDecoration(color: Colors.white),
      child: isWeb
          ? Row(
              children: [
                const Icon(Icons.shopping_cart_outlined, size: 18, color: AppColors.textGrey),
                const SizedBox(width: 8),
                Text(
                  '${filtrados.length} pedidos',
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  height: 36,
                  child: TextField(
                    controller: _busca,
                    decoration: const InputDecoration(
                      hintText: 'Nome, #pedido, etiqueta',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                _dateField(label: 'Início', value: _dataInicio, onTap: () => _pickDate(isInicio: true)),
                const SizedBox(width: 8),
                _dateField(label: 'Fim', value: _dataFim, onTap: () => _pickDate(isInicio: false)),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _statusFilter == null ? 'Filtrar' : StatusPedido.fromString(_statusFilter!).label,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  onSelected: (status) async {
                    setState(() {
                      _statusFilter = status == 'todos' ? null : status;
                    });
                    await _applyFilters();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'todos', child: Text('Todos')),
                    const PopupMenuItem(value: 'pendente', child: Text('Pendentes')),
                    const PopupMenuItem(value: 'confirmado', child: Text('Confirmados')),
                    const PopupMenuItem(value: 'em_preparo', child: Text('Em preparo')),
                    const PopupMenuItem(value: 'pronto_retirada', child: Text('Pronto p/ retirar')),
                    const PopupMenuItem(value: 'saiu_entrega', child: Text('Saiu p/ entrega')),
                    const PopupMenuItem(value: 'entregue', child: Text('Entregues')),
                    const PopupMenuItem(value: 'cancelado', child: Text('Cancelados')),
                  ],
                ),
                const SizedBox(width: 8),
                _buildViewCombo(),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => showNovoPedidoModal(context),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Novo Pedido'),
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 18, color: AppColors.textGrey),
                    const SizedBox(width: 8),
                    Text(
                      '${filtrados.length}',
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          controller: _busca,
                          decoration: const InputDecoration(
                            hintText: 'Nome, #pedido',
                            prefixIcon: Icon(Icons.search, size: 18),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildViewCombo(),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _dateField(label: 'Início', value: _dataInicio, onTap: () => _pickDate(isInicio: true)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _dateField(label: 'Fim', value: _dataFim, onTap: () => _pickDate(isInicio: false)),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.filter_list, size: 16),
                            SizedBox(width: 6),
                            Text('Filtrar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      onSelected: (status) async {
                        setState(() {
                          _statusFilter = status == 'todos' ? null : status;
                        });
                        await _applyFilters();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'todos', child: Text('Todos')),
                        const PopupMenuItem(value: 'pendente', child: Text('Pendentes')),
                        const PopupMenuItem(value: 'confirmado', child: Text('Confirmados')),
                        const PopupMenuItem(value: 'em_preparo', child: Text('Em preparo')),
                        const PopupMenuItem(value: 'pronto_retirada', child: Text('Pronto p/ retirar')),
                        const PopupMenuItem(value: 'saiu_entrega', child: Text('Saiu p/ entrega')),
                        const PopupMenuItem(value: 'entregue', child: Text('Entregues')),
                        const PopupMenuItem(value: 'cancelado', child: Text('Cancelados')),
                      ],
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => showNovoPedidoModal(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Icon(Icons.add, size: 18),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildViewCombo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          value: _quadro,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          items: const [
            DropdownMenuItem(
              value: true,
              child: Row(
                children: [
                  Icon(Icons.view_kanban_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Quadro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: false,
              child: Row(
                children: [
                  Icon(Icons.view_list_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Lista', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _quadro = v);
          },
        ),
      ),
    );
  }

  Widget _dateField({required String label, required DateTime? value, required VoidCallback onTap}) {
    final fmt = DateFormat('dd/MM/yy');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
          color: value != null ? AppColors.primaryLight : Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textGrey),
            const SizedBox(width: 6),
            Text(
              value == null ? label : fmt.format(value),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value == null ? AppColors.textGrey : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBar() {
    final fmt = DateFormat('dd/MM/yyyy');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_statusFilter != null)
            _activeChip(
              label: StatusPedido.fromString(_statusFilter!).label,
              onRemove: () async {
                setState(() => _statusFilter = null);
                await _applyFilters();
              },
            ),
          if (_dataInicio != null)
            _activeChip(
              label: 'De ${fmt.format(_dataInicio!)}',
              onRemove: () async {
                setState(() => _dataInicio = null);
                await _applyFilters();
              },
            ),
          if (_dataFim != null)
            _activeChip(
              label: 'Até ${fmt.format(_dataFim!)}',
              onRemove: () async {
                setState(() => _dataFim = null);
                await _applyFilters();
              },
            ),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Limpar tudo', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _activeChip({required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 4, bottom: 4),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  List<PedidoModel> _filtrados(List<PedidoModel> all) {
    final q = _busca.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((p) {
      final et = (p.etiqueta ?? '').toLowerCase();
      return '#${p.id}'.contains(q) || p.clienteNome.toLowerCase().contains(q) || et.contains(q);
    }).toList();
  }

  Widget _buildError(String error, BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: AppColors.error),
        const SizedBox(height: 16),
        Text('Erro ao carregar pedidos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          error,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textGrey),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _loadData, child: const Text('Tentar novamente')),
      ],
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('Nenhum pedido encontrado', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      ],
    ),
  );

  Widget _buildMobileList(List<PedidoModel> filtrados) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filtrados.length + 1,
      itemBuilder: (context, index) {
        if (index == filtrados.length) {
          return const SizedBox(height: 80);
        }
        return _PedidoCard(pedido: filtrados[index]);
      },
    );
  }

  Widget _buildWebTable(PedidoProvider provider, List<PedidoModel> filtrados) {
    final numberFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM HH:mm');

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    'PEDIDO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGrey),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'CLIENTE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGrey),
                  ),
                ),
                Expanded(
                  child: Text(
                    'DATA',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGrey),
                  ),
                ),
                Expanded(
                  child: Text(
                    'ORIGEM',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGrey),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'STATUS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGrey),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'TOTAL',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGrey),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              itemCount: filtrados.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (context, index) {
                final pedido = filtrados[index];
                return InkWell(
                  onTap: () => showPedidoDetalheModal(context, pedido.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            '#${pedido.id}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            pedido.clienteNome,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            dateFormat.format(pedido.createdAt),
                            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              pedido.origemLabel,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(int.parse(pedido.statusColor.replaceFirst('#', '0xff')))
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              pedido.statusLabel,
                              style: TextStyle(
                                color: Color(int.parse(pedido.statusColor.replaceFirst('#', '0xff'))),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            numberFormat.format(pedido.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.textDark,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final PedidoModel pedido;
  const _PedidoCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final numberFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: () => showPedidoDetalheModal(context, pedido.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(int.parse(pedido.statusColor.replaceFirst('#', '0xff'))),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('#${pedido.id}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Color(int.parse(pedido.statusColor.replaceFirst('#', '0xff'))).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pedido.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(int.parse(pedido.statusColor.replaceFirst('#', '0xff'))),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(pedido.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(pedido.clienteNome, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                '${pedido.itens.length} itens • ${pedido.origemLabel}',
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      pedido.origemLabel,
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    numberFormat.format(pedido.total),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
