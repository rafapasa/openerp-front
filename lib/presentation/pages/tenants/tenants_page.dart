// lib/presentation/pages/tenants/tenants_page.dart
// Refatorado eTools - Responsivo Web (tabela) + Mobile (cards)
import 'package:flutter/material.dart';
import 'package:openerp_front/core/config/api_config.dart';
import 'package:openerp_front/data/models/tenant_model.dart';
import 'package:openerp_front/presentation/pages/tenants/tenant_detalhe_modal.dart';
import 'package:openerp_front/presentation/pages/tenants/form_tenant_page.dart';
import 'package:openerp_front/presentation/providers/tenant_provider.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class TenantsPage extends StatefulWidget {
  const TenantsPage({super.key});

  @override
  State<TenantsPage> createState() => _TenantsPageState();
}

class _TenantsPageState extends State<TenantsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _switchingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenantProvider>().carregarTenants();
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getAvatarColor(String name) {
    final colors = [AppColors.primary, const Color(0xFF0EA5E9), AppColors.accent, const Color(0xFFF59E0B)];
    return colors[name.hashCode % colors.length];
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return name.isNotEmpty ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase() : '?';
  }

  String _formatCnpj(String? cnpj) {
    if (cnpj == null || cnpj.length != 14) return cnpj ?? '';
    return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12, 14)}';
  }

  Future<void> _usarComoWebhook(TenantModel tenant) async {
    final id = tenant.id;
    if (id == null || _switchingId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usar como webhook'),
        content: Text(
          'Apontar o WhatsApp de teste para "${tenant.nome}"?\n\n'
          'Mensagens do número de teste passam a cair nesta empresa.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _switchingId = id);
    final provider = context.read<TenantProvider>();
    final phone = await provider.usarComoWebhook(id);
    if (!mounted) return;
    setState(() => _switchingId = null);

    if (provider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            phone != null && phone.isNotEmpty
                ? 'Webhook ativo em "${tenant.nome}" ($phone)'
                : 'Webhook ativo em "${tenant.nome}"',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Falha ao apontar webhook'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  /// Botão direto (sem PopupMenu) — fora do InkWell da linha para não engolir o toque.
  Widget _btnWebhook(TenantModel tenant) {
    if (!ApiConfig.isDev) return const SizedBox.shrink();
    final busy = _switchingId == tenant.id;
    return TextButton.icon(
      onPressed: busy ? null : () => _usarComoWebhook(tenant),
      icon: busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.swap_horiz, size: 16),
      label: Text(
        busy ? 'Trocando…' : 'Usar como webhook',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;
    final showWebhook = ApiConfig.isDev;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<TenantProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.tenants.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.error != null && provider.tenants.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Erro ao carregar empresas',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => provider.carregarTenants(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final filtered = provider.tenants.where((t) {
            return t.nome.toLowerCase().contains(_searchQuery) || (t.cnpj ?? '').toLowerCase().contains(_searchQuery);
          }).toList();

          return Padding(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isWeb ? 20 : 16),
                  decoration: isWeb ? AppTheme.cardDecoration : const BoxDecoration(color: Colors.white),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Buscar empresa por nome ou CNPJ',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => _searchController.clear(),
                                      )
                                    : const Icon(Icons.tune, size: 18),
                              ),
                            ),
                          ),
                          if (isWeb) ...[
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: () =>
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FormTenantPage())),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Nova Empresa'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '${filtered.length} empresas',
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (showWebhook) ...[
                            const SizedBox(width: 12),
                            Text(
                              '· dev: webhook',
                              style: TextStyle(color: Colors.orange[700], fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: AppColors.success),
                                SizedBox(width: 4),
                                Text(
                                  'Sincronizado',
                                  style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                provider.tenants.isEmpty ? 'Nenhuma empresa cadastrada' : 'Nenhum resultado',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 16),
                              if (provider.tenants.isEmpty)
                                FilledButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const FormTenantPage()),
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Criar empresa'),
                                ),
                            ],
                          ),
                        )
                      : isWeb
                      ? _buildWebTable(filtered, showWebhook)
                      : _buildMobileList(filtered),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: MediaQuery.of(context).size.width > 800
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormTenantPage())),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nova', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
    );
  }

  Widget _buildMobileList(List<TenantModel> filtered) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<TenantProvider>().carregarTenants(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tenant = filtered[index];
          return Container(
            decoration: AppTheme.cardDecoration,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => showTenantDetalheModal(context, tenant),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: AppTheme.avatarDecoration(_getAvatarColor(tenant.nome)),
                            child: Center(
                              child: Text(
                                _getInitials(tenant.nome),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tenant.nome,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.badge_outlined, size: 14, color: AppColors.textGrey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _formatCnpj(tenant.cnpj),
                                        style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.successBg,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Ativo',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (ApiConfig.isDev) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _btnWebhook(tenant),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebTable(List<TenantModel> filtered, bool showWebhook) {
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
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'EMPRESA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textGrey,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'CNPJ',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGrey),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'PLANO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGrey),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'STATUS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGrey),
                  ),
                ),
                if (showWebhook)
                  const SizedBox(
                    width: 160,
                    child: Text(
                      'AÇÕES',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGrey),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (context, index) {
                final tenant = filtered[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: () => showTenantDetalheModal(context, tenant),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _getAvatarColor(tenant.nome),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(tenant.nome),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tenant.nome,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatCnpj(tenant.cnpj),
                          style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Premium',
                            style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 8, color: AppColors.success),
                              SizedBox(width: 4),
                              Text(
                                'Ativa',
                                style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (showWebhook)
                        SizedBox(
                          width: 160,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _btnWebhook(tenant),
                          ),
                        ),
                    ],
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
