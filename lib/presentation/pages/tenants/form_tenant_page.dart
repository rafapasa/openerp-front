// lib/presentation/pages/tenants/form_tenant_page.dart
// Refatorado eTools - Responsivo e bonito
import 'package:flutter/material.dart';
import 'package:front_openerp/data/models/tenant_model.dart';
import 'package:front_openerp/presentation/providers/tenant_provider.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class FormTenantPage extends StatefulWidget {
  final TenantModel? tenant;

  const FormTenantPage({super.key, this.tenant});

  @override
  State<FormTenantPage> createState() => _FormTenantPageState();
}

class _FormTenantPageState extends State<FormTenantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  bool _ativo = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.tenant != null) {
      _nomeController.text = widget.tenant!.nome;
      _cnpjController.text = widget.tenant!.cnpj ?? '';
      _emailController.text = widget.tenant!.email ?? '';
      _telefoneController.text = widget.tenant!.telefone ?? '';
      _enderecoController.text = widget.tenant!.endereco ?? '';
      _ativo = widget.tenant!.ativo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.tenant == null ? 'Nova Empresa' : 'Editar Empresa',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWeb ? 720 : double.infinity),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWeb ? 24 : 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header Card
                  if (widget.tenant == null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.business, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nova Empresa',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Preencha os dados para cadastrar uma nova empresa no ERPCloud',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.tenant == null) const SizedBox(height: 20),

                  // Form Card
                  Container(
                    padding: EdgeInsets.all(isWeb ? 28 : 20),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            const Text('Dados da Empresa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome da Empresa *',
                            hintText: 'Ex: FastFood do Zé',
                            prefixIcon: Icon(Icons.business_outlined, size: 20),
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? 'Nome é obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, c) {
                            final twoCols = c.maxWidth > 500;
                            if (twoCols) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _cnpjController,
                                      decoration: const InputDecoration(
                                        labelText: 'CNPJ',
                                        hintText: '00.000.000/0000-00',
                                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.border),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: SwitchListTile(
                                        title: const Text('Ativo', style: TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Text(
                                          _ativo ? 'Empresa ativa' : 'Inativa',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                                        ),
                                        value: _ativo,
                                        activeThumbColor: AppColors.accent,
                                        contentPadding: EdgeInsets.zero,
                                        onChanged: (value) => setState(() => _ativo = value),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  TextFormField(
                                    controller: _cnpjController,
                                    decoration: const InputDecoration(
                                      labelText: 'CNPJ',
                                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SwitchListTile(
                                    title: const Text('Ativo'),
                                    value: _ativo,
                                    activeThumbColor: AppColors.accent,
                                    onChanged: (v) => setState(() => _ativo = v),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.call_outlined, size: 20, color: AppColors.accent),
                            ),
                            const SizedBox(width: 10),
                            const Text('Contato', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            hintText: 'contato@empresa.com.br',
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _telefoneController,
                          decoration: const InputDecoration(
                            labelText: 'Telefone',
                            hintText: '(00) 00000-0000',
                            prefixIcon: Icon(Icons.phone_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _enderecoController,
                          decoration: const InputDecoration(
                            labelText: 'Endereço',
                            hintText: 'Rua, número, bairro, cidade - UF',
                            prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Ações
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _isSaving
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                            : FilledButton.icon(
                                onPressed: _salvar,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.save_outlined, size: 18),
                                label: Text(
                                  widget.tenant == null ? 'Criar Empresa' : 'Salvar Alterações',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/Icone_azul_500x500.png',
                        width: 14,
                        height: 14,
                        errorBuilder: (_, _, _) => const Icon(Icons.bolt, size: 12, color: AppColors.primary),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Protegido por eTools Tecnologia',
                        style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final tenant = TenantModel(
      id: widget.tenant?.id,
      nome: _nomeController.text.trim(),
      cnpj: _cnpjController.text.isNotEmpty ? _cnpjController.text.trim() : null,
      email: _emailController.text.isNotEmpty ? _emailController.text.trim() : null,
      telefone: _telefoneController.text.isNotEmpty ? _telefoneController.text.trim() : null,
      endereco: _enderecoController.text.isNotEmpty ? _enderecoController.text.trim() : null,
      ativo: _ativo,
    );

    try {
      final provider = context.read<TenantProvider>();
      if (widget.tenant == null) {
        await provider.criarTenant(tenant);
      } else {
        await provider.atualizarTenant(tenant);
      }

      if (provider.error == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Salvo com sucesso!'),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      } else if (provider.error != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: ${provider.error}'), backgroundColor: AppColors.error));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }
}
