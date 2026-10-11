// lib/presentation/layout/main_layout.dart
import 'package:flutter/material.dart';
import 'package:front_openerp/presentation/pages/auth/conta_page.dart';
import 'package:front_openerp/presentation/pages/auth/login_page.dart';
import 'package:front_openerp/presentation/pages/auth/selecionar_tenant_page.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';

class MainLayout extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget child;
  final String? title;

  const MainLayout({super.key, required this.currentIndex, required this.onTap, required this.child, this.title});

  Future<void> _sair(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  Future<void> _trocarEmpresa(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.trocarEmpresa();
    if (!context.mounted) return;
    if (auth.contas.length > 1) {
      Navigator.of(context)
          .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SelecionarTenantPage()), (_) => false);
      return;
    }
    await auth.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 800;
        final auth = context.watch<AuthProvider>();

        // ✅ CORRIGIDO: null-safety no `nome`
        final usuario = auth.usuario;
        final nome = (usuario?.nome?.isNotEmpty == true) ? usuario!.nome! : (usuario?.email ?? 'Usuário');

        // ✅ CORRIGIDO: agora `nome` é garantidamente String não-nulo
        final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : 'U';

        // ✅ CORRIGIDO: depende do campo `role` existir no UsuarioModel
        // Se NÃO existir, use: final role = usuario?.email ?? '';
        final role = usuario?.role ?? '';

        if (isWeb) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                _BarraLateral(
                  builder: (recolhida, recolher) => Container(
                    width: recolhida ? 76 : 268,
                    color: AppColors.primaryDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: recolhida ? 'Expandir menu' : 'Recolher menu',
                            onPressed: recolher,
                            icon: Icon(recolhida ? Icons.chevron_right : Icons.chevron_left, color: Colors.white),
                          ),
                        ),
                        if (!recolhida)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Image.asset(
                              'assets/images/Logo_openerp_3D.png',
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, _, _) => const Text(
                                'OpenERP',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        _SideItem(
                          icon: Icons.dashboard_outlined,
                          label: 'Dashboard',
                          compact: recolhida,
                          selected: currentIndex == 0,
                          onTap: () => onTap(0),
                        ),
                        _SideItem(
                          icon: Icons.shopping_cart_outlined,
                          label: 'Pedidos',
                          compact: recolhida,
                          selected: currentIndex == 1,
                          onTap: () => onTap(1),
                        ),
                        _SideItem(
                          icon: Icons.people_outline,
                          label: 'Clientes',
                          compact: recolhida,
                          selected: currentIndex == 2,
                          onTap: () => onTap(2),
                        ),
                        _SideItem(
                          icon: Icons.inventory_2_outlined,
                          label: 'Produtos',
                          compact: recolhida,
                          selected: currentIndex == 3,
                          onTap: () => onTap(3),
                        ),
                        _SideItem(
                          icon: Icons.category_outlined,
                          label: 'Categorias',
                          compact: recolhida,
                          selected: currentIndex == 4,
                          onTap: () => onTap(4),
                        ),
                        _SideItem(
                          icon: Icons.business_outlined,
                          label: 'Empresas',
                          compact: recolhida,
                          selected: currentIndex == 5,
                          onTap: () => onTap(5),
                        ),
                        const Spacer(),
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.1),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        const SizedBox(height: 12),
                        if (auth.hasMultipleTenants)
                          _SideItem(
                            icon: Icons.swap_horiz,
                            label: 'Trocar empresa',
                            compact: recolhida,
                            selected: false,
                            onTap: () => _trocarEmpresa(context),
                          ),
                        _SideItem(
                          icon: Icons.logout,
                          label: 'Sair',
                          compact: recolhida,
                          selected: false,
                          onTap: () => _sair(context),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                  child: Center(
                                    child: Text(
                                      inicial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nome,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      // ✅ role agora é String não-nulo
                                      Text(role, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'OpenERP by eTools',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 68,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title ?? _getTitle(currentIndex),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            if (auth.hasMultipleTenants)
                              constraints.maxWidth > 1100
                                  ? TextButton.icon(
                                      onPressed: () => _trocarEmpresa(context),
                                      icon: const Icon(Icons.swap_horiz, size: 18),
                                      label: const Text('Trocar empresa'),
                                    )
                                  : IconButton(
                                      tooltip: 'Trocar empresa',
                                      onPressed: () => _trocarEmpresa(context),
                                      icon: const Icon(Icons.swap_horiz),
                                    ),
                            IconButton(
                              tooltip: 'Sair',
                              onPressed: () => _sair(context),
                              icon: const Icon(Icons.logout, color: AppColors.textGrey),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              tooltip: 'Conta',
                              onSelected: (v) {
                                if (v == 'empresa') _trocarEmpresa(context);
                                if (v == 'conta') {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContaPage()));
                                }
                                if (v == 'sair') _sair(context);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'empresa', child: Text('Troca de empresa')),
                                PopupMenuItem(value: 'conta', child: Text('Dados da Conta')),
                                PopupMenuItem(value: 'sair', child: Text('Logout')),
                              ],
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primary,
                                child: Text(inicial, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 1, color: AppColors.border),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(title ?? _getTitle(currentIndex)),
            actions: [
              if (auth.hasMultipleTenants)
                IconButton(
                  tooltip: 'Trocar empresa',
                  onPressed: () => _trocarEmpresa(context),
                  icon: const Icon(Icons.swap_horiz),
                ),
              PopupMenuButton<String>(
                tooltip: 'Conta',
                onSelected: (v) {
                  if (v == 'empresa') _trocarEmpresa(context);
                  if (v == 'conta') Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContaPage()));
                  if (v == 'sair') _sair(context);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'empresa', child: Text('Troca de empresa')),
                  PopupMenuItem(value: 'conta', child: Text('Dados da Conta')),
                  PopupMenuItem(value: 'sair', child: Text('Logout')),
                ],
                icon: const Icon(Icons.account_circle),
              ),
            ],
          ),
          body: child,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)],
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textGrey,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart_outlined),
                  activeIcon: Icon(Icons.shopping_cart),
                  label: 'Pedidos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Clientes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2),
                  label: 'Produtos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.category_outlined),
                  activeIcon: Icon(Icons.category),
                  label: 'Categorias',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.business_outlined),
                  activeIcon: Icon(Icons.business),
                  label: 'Empresas',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTitle(int i) {
    const titles = ['Dashboard', 'Pedidos', 'Clientes', 'Produtos', 'Categorias', 'Empresas'];
    return titles[i.clamp(0, titles.length - 1)];
  }
}

class _BarraLateral extends StatefulWidget {
  final Widget Function(bool recolhida, VoidCallback recolher) builder;
  const _BarraLateral({required this.builder});
  @override
  State<_BarraLateral> createState() => _BarraLateralState();
}

class _BarraLateralState extends State<_BarraLateral> {
  bool _recolhida = false;
  @override
  Widget build(BuildContext context) => widget.builder(_recolhida, () => setState(() => _recolhida = !_recolhida));
}

class _SideItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _SideItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: selected ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 20),
        title: compact
            ? null
            : Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
        trailing: !compact && selected
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              )
            : null,
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
