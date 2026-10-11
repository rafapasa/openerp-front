import 'package:flutter/material.dart';
import 'package:front_openerp/presentation/widgets/viewport_box.dart';
import 'package:front_openerp/data/models/tenant_notificacao_model.dart';
import 'package:front_openerp/presentation/providers/tenant_provider.dart';
import 'package:front_openerp/presentation/theme/app_colors.dart';
import 'package:front_openerp/presentation/widgets/app_section_card.dart';
import 'package:provider/provider.dart';

Future<TenantNotificacaoModel?> showTenantNotificacaoFormDialog(
  BuildContext context, {
  required int tenantId,
  TenantNotificacaoModel? notificacao,
}) {
  return showDialog<TenantNotificacaoModel>(
    context: context,
    barrierDismissible: false,
    builder: (_) => TenantNotificacaoFormDialog(tenantId: tenantId, notificacao: notificacao),
  );
}

class TenantNotificacaoFormDialog extends StatefulWidget {
  final int tenantId;
  final TenantNotificacaoModel? notificacao;
  const TenantNotificacaoFormDialog({super.key, required this.tenantId, this.notificacao});

  @override
  State<TenantNotificacaoFormDialog> createState() => _TenantNotificacaoFormDialogState();
}

class _TenantNotificacaoFormDialogState extends State<TenantNotificacaoFormDialog> {
  final _destino = TextEditingController();
  String _canal = 'whatsapp';
  String _evento = 'novo_pedido';
  bool _ativo = true;
  bool _saving = false;

  bool get _editando => widget.notificacao != null;

  @override
  void initState() {
    super.initState();
    final n = widget.notificacao;
    if (n != null) {
      _destino.text = n.destino;
      _canal = n.canal;
      _evento = n.evento;
      _ativo = n.ativo;
    }
  }

  @override
  void dispose() {
    _destino.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_destino.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Destino e obrigatorio')));
      return;
    }
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'canal': _canal,
      'destino': _destino.text.trim(),
      'evento': _evento,
      'ativo': _ativo,
    };
    final provider = context.read<TenantProvider>();
    final result = _editando
        ? await provider.atualizarNotificacao(widget.tenantId, widget.notificacao!.id!, payload)
        : await provider.criarNotificacao(widget.tenantId, payload);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Erro ao salvar')));
      return;
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: caixaDaJanela(context, maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _editando ? 'Editar notificacao' : 'Nova notificacao',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(onPressed: _saving ? null : () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              Expanded(
                child: ListView(
                  children: [
                    AppSectionCard(
                      titulo: 'Configuracao',
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _canal,
                            decoration: const InputDecoration(labelText: 'Canal'),
                            items: const [DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp'))],
                            onChanged: _saving ? null : (v) => setState(() => _canal = v ?? 'whatsapp'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _destino,
                            enabled: !_saving,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Destino (telefone)',
                              hintText: '5547999999999',
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _evento,
                            decoration: const InputDecoration(labelText: 'Evento'),
                            items: const [DropdownMenuItem(value: 'novo_pedido', child: Text('Novo pedido'))],
                            onChanged: _saving ? null : (v) => setState(() => _evento = v ?? 'novo_pedido'),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Ativo'),
                            value: _ativo,
                            activeThumbColor: AppColors.accent,
                            onChanged: _saving ? null : (v) => setState(() => _ativo = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _saving ? null : _salvar,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_editando ? 'Salvar' : 'Criar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
