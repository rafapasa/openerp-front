import 'package:flutter/material.dart';
import 'package:front_openerp/core/helpers/snack_helper.dart';
import 'package:front_openerp/data/models/tenant_model.dart';
import 'package:front_openerp/presentation/providers/tenant_provider.dart';
import 'package:front_openerp/presentation/theme/app_colors.dart';
import 'package:front_openerp/presentation/widgets/app_section_card.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TenantDadosTab extends StatefulWidget {
  final TenantModel tenant;
  final ValueChanged<TenantModel> onSaved;
  const TenantDadosTab({super.key, required this.tenant, required this.onSaved});

  @override
  State<TenantDadosTab> createState() => _TenantDadosTabState();
}

class _TenantDadosTabState extends State<TenantDadosTab> {
  late TextEditingController _nome;
  late TextEditingController _cnpj;
  late TextEditingController _email;
  late TextEditingController _telefone;
  late TextEditingController _endereco;
  bool _editando = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarValores();
  }

  void _carregarValores() {
    _nome = TextEditingController(text: widget.tenant.nome);
    _cnpj = TextEditingController(text: widget.tenant.cnpj ?? '');
    _email = TextEditingController(text: widget.tenant.email ?? '');
    _telefone = TextEditingController(text: widget.tenant.telefone ?? '');
    _endereco = TextEditingController(text: widget.tenant.endereco ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _cnpj.dispose();
    _email.dispose();
    _telefone.dispose();
    _endereco.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nome.text.trim().isEmpty) {
      showSavedSnack(context, message: 'Nome e obrigatorio');
      return;
    }
    setState(() => _salvando = true);
    final provider = context.read<TenantProvider>();
    final atualizado = widget.tenant.copyWith(
      nome: _nome.text.trim(),
      cnpj: _cnpj.text.trim().isEmpty ? null : _cnpj.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      telefone: _telefone.text.trim().isEmpty ? null : _telefone.text.trim(),
      endereco: _endereco.text.trim().isEmpty ? null : _endereco.text.trim(),
    );
    await provider.atualizarTenant(atualizado);
    if (!mounted) return;
    setState(() => _salvando = false);
    if (provider.error != null) {
      showSavedSnack(context, message: provider.error ?? 'Erro ao salvar');
      return;
    }
    setState(() => _editando = false);
    widget.onSaved(atualizado);
    showSavedSnack(context, message: 'Salvo');
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Informacoes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              if (!_editando)
                TextButton.icon(
                  onPressed: () => setState(() => _editando = true),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                )
              else
                Row(
                  children: [
                    TextButton(
                      onPressed: _salvando
                          ? null
                          : () {
                              _carregarValores();
                              setState(() => _editando = false);
                            },
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _salvando ? null : _salvar,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                      child: _salvando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Salvar'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          _campo('Nome', _nome, editando: _editando),
          _campo('CNPJ', _cnpj, editando: _editando),
          _campo('E-mail', _email, editando: _editando),
          _campo('Telefone', _telefone, editando: _editando),
          _campo('Endereco', _endereco, editando: _editando, maxLines: 2),
          const SizedBox(height: 16),
          AppSectionCard(
            titulo: 'Auditoria',
            child: Column(
              children: [
                if (widget.tenant.createdAt != null) _info('Criado em', dateFormat.format(widget.tenant.createdAt!)),
                if (widget.tenant.updatedAt != null)
                  _info('Atualizado em', dateFormat.format(widget.tenant.updatedAt!)),
                _info('ID', widget.tenant.id?.toString() ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl, {required bool editando, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        enabled: editando,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
