// lib/presentation/pages/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:front_openerp/presentation/pages/auth/selecionar_tenant_page.dart';
import 'package:front_openerp/presentation/pages/home_page.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'etoolstec@etoolstec.com.br');
  final _passwordController = TextEditingController(text: 'admin123');
  bool _obscurePassword = true;
  bool _lembrarMe = true;

  static const _navy = Color(0xFF0B2A5B);
  static const _fieldFill = Color(0xFFF3F5F8);

  static const _logoAssets = [
    'assets/images/Logo_openerp.png',
    'assets/images/Logo_fundo_transparente.png',
    'assets/images/OpenERP_transparente_v2.png',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(_emailController.text.trim(), _passwordController.text.trim());
    if (!success || !mounted) return;
    if (authProvider.precisaSelecionarConta) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SelecionarTenantPage()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  InputDecoration _fieldDeco({required String hint, required IconData prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: _fieldFill,
      prefixIcon: Icon(prefix, size: 20, color: AppColors.textGrey),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Widget _logo() {
    Widget img(String path, {required Widget Function() orElse}) {
      return Image.asset(
        path,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.centerLeft,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => orElse(),
      );
    }

    return img(
      _logoAssets[0],
      orElse: () => img(
        _logoAssets[1],
        orElse: () => img(
          _logoAssets[2],
          orElse: () => const Text(
            'OpenERP',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _securityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: Color(0xFF7EE0E8), size: 42),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Segurança & Confiabilidade',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.2),
                ),
                SizedBox(height: 6),
                Text(
                  'Dados protegidos com criptografia e conformidade LGPD.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: double.infinity, child: _logo()),
        const SizedBox(height: 36),
        const Text(
          'Soluções inteligentes\npara sua empresa.',
          style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, height: 1.15),
        ),
        const SizedBox(height: 16),
        const Text(
          'Gerencie pedidos, clientes e produtos\nem um só lugar.',
          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
        ),
        const SizedBox(height: 36),
        _securityCard(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWeb = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF062047), AppColors.primaryDark, AppColors.primary, Color(0xFF2A6ACF)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 20, vertical: 32),
              child: isWeb
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 6, child: _brandColumn()),
                        const SizedBox(width: 40),
                        Expanded(flex: 5, child: _buildFormCard(auth)),
                      ],
                    )
                  : ListView(children: [_brandColumn(), const SizedBox(height: 28), _buildFormCard(auth)]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(AuthProvider auth) {
    final isLoading = auth.isLoading;
    final error = auth.error;

    return Align(
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.fromLTRB(36, 36, 36, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 32, offset: const Offset(0, 16)),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bem-vindo!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _navy),
              ),
              const SizedBox(height: 8),
              const Text(
                'Faça login para continuar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.textGrey),
              ),
              const SizedBox(height: 28),
              const Text(
                'E-mail',
                style: TextStyle(fontWeight: FontWeight.w700, color: _navy, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldDeco(hint: 'seu@email.com', prefix: Icons.mail_outline),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Digite seu e-mail';
                  if (!value.contains('@')) return 'E-mail inválido';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Senha',
                style: TextStyle(fontWeight: FontWeight.w700, color: _navy, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _fieldDeco(
                  hint: '••••••••',
                  prefix: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textGrey,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Digite sua senha';
                  if (value.length < 6) return 'Senha deve ter no mínimo 6 caracteres';
                  return null;
                },
                onFieldSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _lembrarMe,
                      onChanged: (v) => setState(() => _lembrarMe = v ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Lembrar-me', style: TextStyle(fontSize: 13, color: _navy)),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Recuperação de senha em breve.')));
                    },
                    child: const Text('Esqueceu a senha?'),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: isLoading ? null : _login,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Entrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Não tem uma conta?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Cadastro público ainda não está liberado.')));
                },
                child: const Text(
                  'Criar conta',
                  style: TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
