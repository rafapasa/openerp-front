// lib/presentation/pages/auth/selecionar_tenant_page.dart
// Refatorado eTools
import 'package:flutter/material.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/presentation/pages/auth/login_page.dart';
import 'package:front_openerp/presentation/pages/home_page.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class SelecionarTenantPage extends StatelessWidget {
  const SelecionarTenantPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final contas = authProvider.contas;
    final primeiroConta = contas.isNotEmpty ? contas.first : null;
    final usuario = authProvider.usuario;
    final isWeb = MediaQuery.of(context).size.width > 800;

    final nomeExibicao = primeiroConta?.nome.isNotEmpty == true
        ? primeiroConta!.nome
        : primeiroConta?.email.isNotEmpty == true
        ? primeiroConta!.email
        : usuario?.nome ?? usuario?.email ?? 'Usuário';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Selecionar Empresa', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWeb ? 720 : double.infinity),
          child: Padding(
            padding: EdgeInsets.all(isWeb ? 32 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.person_outline, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olá, $nomeExibicao!',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Você tem acesso a ${contas.length} empresa(s). Selecione qual deseja acessar:',
                              style: const TextStyle(fontSize: 13, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Empresas disponíveis',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: isWeb
                      ? GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: contas.length,
                          itemBuilder: (context, index) => _ContaCard(
                            conta: contas[index],
                            onTap: () => _selecionarEmpresa(context, contas[index].tenant.id),
                          ),
                        )
                      : ListView.separated(
                          itemCount: contas.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _ContaCard(
                            conta: contas[index],
                            onTap: () => _selecionarEmpresa(context, contas[index].tenant.id),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                      }
                    },
                    icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
                    label: const Text(
                      'Sair',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selecionarEmpresa(BuildContext context, int? tenantId) async {
    if (tenantId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Empresa inválida.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.selectTenant(tenantId);

    if (success && context.mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Erro ao selecionar empresa'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _ContaCard extends StatelessWidget {
  final LoginConta conta;
  final VoidCallback onTap;

  const _ContaCard({required this.conta, required this.onTap});

  Color _getColor(String text) {
    final colors = [AppColors.primary, const Color(0xFF0EA5E9), AppColors.accent, const Color(0xFFF59E0B)];
    return colors[text.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final pessoa = conta.nome.isNotEmpty ? conta.nome : conta.email;

    return Container(
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: _getColor(pessoa).withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Center(
                  child: pessoa.isNotEmpty
                      ? Text(
                          pessoa[0].toUpperCase(),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _getColor(pessoa)),
                        )
                      : Icon(Icons.business, color: _getColor(pessoa)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${conta.tenant.id} - ${conta.tenant.nome}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        conta.roleLabel,
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (conta.email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        conta.email,
                        style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
