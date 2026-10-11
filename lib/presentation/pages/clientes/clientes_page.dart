// lib/presentation/pages/clientes/clientes_page.dart
// Refatorado eTools - Responsivo Web tabela + Mobile cards
import 'package:flutter/material.dart';
import 'package:front_openerp/presentation/pages/clientes/cliente_detalhe_modal.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

import 'package:front_openerp/presentation/pages/clientes/novo_cliente_dialog.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  bool _cards = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<ClienteProvider>();
    await provider.loadClientes();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      final provider = context.read<ClienteProvider>();
      if (!provider.isLoadingMore && provider.hasMore) provider.loadMore();
    }
  }

  Future<void> _refreshData() async => await context.read<ClienteProvider>().refreshClientes();

  void _search(String query) {
    final provider = context.read<ClienteProvider>();
    if (query.isEmpty) {
      provider.loadClientes();
    } else {
      provider.searchByNome(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClienteProvider>();
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Toolbar
            Container(
              padding: EdgeInsets.all(isWeb ? 20 : 16),
              decoration: isWeb ? AppTheme.cardDecoration : const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _search,
                      decoration: InputDecoration(
                        hintText: 'Buscar cliente por nome, telefone...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _search('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _seletorVisual(),
                  if (isWeb) ...[
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => showNovoClienteDialog(context),
                      icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                      label: const Text('Novo Cliente'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : provider.error != null
                  ? _buildError(provider.error!, context)
                  : provider.clientes.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _refreshData,
                      child: _cards ? _buildCards(provider) : (isWeb ? _buildWebTable(provider) : _buildMobileList(provider)),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: isWeb
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showNovoClienteDialog(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Novo', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
    );
  }

  Widget _buildError(String error, BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: AppColors.error),
        const SizedBox(height: 16),
        Text('Erro ao carregar clientes', style: Theme.of(context).textTheme.titleLarge),
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
        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('Nenhum cliente encontrado', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      ],
    ),
  );

  Widget _seletorVisual() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          value: _cards,
          isDense: true,
          items: const [
            DropdownMenuItem(value: false, child: Text('Lista')),
            DropdownMenuItem(value: true, child: Text('Card')),
          ],
          onChanged: (v) { if (v != null) setState(() => _cards = v); },
        ),
      ),
    );
  }

  Widget _buildCards(ClienteProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 360, mainAxisExtent: 150, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: provider.clientes.length,
      itemBuilder: (_, i) => _ClienteCard(cliente: provider.clientes[i]),
    );
  }

  Widget _buildMobileList(ClienteProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: provider.clientes.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.clientes.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        return _ClienteCard(cliente: provider.clientes[index]);
      },
    );
  }

  Widget _buildWebTable(ClienteProvider provider) {
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
                Expanded(
                  flex: 3,
                  child: Text(
                    'CLIENTE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textGrey,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'TELEFONE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGrey),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ÚLTIMO PEDIDO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGrey),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'STATUS',
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
              itemCount: provider.clientes.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (context, index) {
                final cliente = provider.clientes[index];
                final dateFormat = DateFormat('dd/MM/yyyy');
                return InkWell(
                  onTap: () => showClienteDetalheModal(context, cliente.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                child: Text(
                                  cliente.nome.isNotEmpty ? cliente.nome[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  cliente.nome,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            cliente.telefone,
                            style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            cliente.ultimoPedidoAt != null ? dateFormat.format(cliente.ultimoPedidoAt!) : 'Nenhum',
                            style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cliente.status == 'ativo' ? AppColors.successBg : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cliente.status == 'ativo' ? 'Ativo' : 'Inativo',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: cliente.status == 'ativo' ? AppColors.success : AppColors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
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

class _ClienteCard extends StatelessWidget {
  final ClienteModel cliente;
  const _ClienteCard({required this.cliente});

  Color _getAvatarColor(String name) {
    final colors = [AppColors.primary, const Color(0xFF0EA5E9), AppColors.accent, const Color(0xFFF59E0B)];
    return colors[name.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: () => showClienteDetalheModal(context, cliente.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _getAvatarColor(cliente.nome).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    cliente.nome.isNotEmpty ? cliente.nome[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _getAvatarColor(cliente.nome)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cliente.nome, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 12, color: AppColors.textGrey),
                        const SizedBox(width: 4),
                        Text(cliente.telefone, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 12, color: AppColors.textGrey),
                        const SizedBox(width: 4),
                        Text(
                          'Último: ${cliente.ultimoPedidoAt != null ? dateFormat.format(cliente.ultimoPedidoAt!) : "Nenhum"}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cliente.status == 'ativo' ? AppColors.successBg : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cliente.status == 'ativo' ? 'Ativo' : 'Inativo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cliente.status == 'ativo' ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
