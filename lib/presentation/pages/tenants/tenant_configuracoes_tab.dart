import 'package:flutter/material.dart';
import 'package:front_openerp/data/models/tenant_notificacao_model.dart';
import 'package:front_openerp/presentation/providers/tenant_provider.dart';
import 'package:front_openerp/presentation/theme/app_colors.dart';
import 'package:front_openerp/presentation/widgets/app_section_card.dart';
import 'package:provider/provider.dart';

import 'tenant_notificacao_form_dialog.dart';

class TenantConfiguracoesTab extends StatefulWidget {
  final int tenantId;
  const TenantConfiguracoesTab({super.key, required this.tenantId});

  @override
  State<TenantConfiguracoesTab> createState() => _TenantConfiguracoesTabState();
}

class _TenantConfiguracoesTabState extends State<TenantConfiguracoesTab> {
  List<TenantNotificacaoModel> _notificacoes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final list = await context.read<TenantProvider>().listarNotificacoes(widget.tenantId);
    if (!mounted) return;
    setState(() {
      _notificacoes = list;
      _loading = false;
    });
  }

  Future<void> _adicionar() async {
    final criado = await showTenantNotificacaoFormDialog(context, tenantId: widget.tenantId);
    if (criado != null) await _carregar();
  }

  Future<void> _editar(TenantNotificacaoModel n) async {
    final atualizado = await showTenantNotificacaoFormDialog(context, tenantId: widget.tenantId, notificacao: n);
    if (atualizado != null) await _carregar();
  }

  Future<void> _excluir(TenantNotificacaoModel n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir configuracao?'),
        content: Text('${n.canal} -> ${n.destino}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    final ok = await context.read<TenantProvider>().excluirNotificacao(widget.tenantId, n.id!);
    if (!mounted) return;
    if (ok) await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Notificacoes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              FilledButton.icon(
                onPressed: _adicionar,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_notificacoes.isEmpty)
            AppSectionCard(
              titulo: 'Nenhuma configuracao',
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Adicione um destino para receber notificacoes de novos pedidos.',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
              ),
            )
          else
            ..._notificacoes.map(
              (n) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          n.ativo ? Icons.check_circle : Icons.pause_circle,
                          size: 16,
                          color: n.ativo ? AppColors.success : AppColors.textGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(n.canal.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Editar',
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _editar(n),
                        ),
                        IconButton(
                          tooltip: 'Excluir',
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          onPressed: () => _excluir(n),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(n.destino, style: const TextStyle(fontSize: 13)),
                    Text('Evento: ${n.evento}', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
