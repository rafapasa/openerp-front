import 'package:flutter/material.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import 'endereco_form_dialog.dart';

class ClienteDadosTab extends StatefulWidget {
  final ClienteModel cliente;
  final VoidCallback onSaved;
  const ClienteDadosTab({super.key, required this.cliente, required this.onSaved});

  @override
  State<ClienteDadosTab> createState() => _ClienteDadosTabState();
}

class _ClienteDadosTabState extends State<ClienteDadosTab> {
  late TextEditingController _nome;
  late TextEditingController _telefone;
  late TextEditingController _nomePerfil;
  late TextEditingController _email;
  late TextEditingController _doc;
  bool _editando = false;
  bool _salvando = false;
  List<EnderecoModel> _enderecos = [];
  bool _carregandoEnderecos = true;

  @override
  void initState() {
    super.initState();
    _carregarValores();
    _carregarEnderecos();
  }

  void _carregarValores() {
    _nome = TextEditingController(text: widget.cliente.nome);
    _telefone = TextEditingController(text: widget.cliente.telefone);
    _nomePerfil = TextEditingController(text: widget.cliente.nomePerfil ?? '');
    _email = TextEditingController(text: widget.cliente.email ?? '');
    _doc = TextEditingController(text: widget.cliente.inscricaoFederal ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _nomePerfil.dispose();
    _email.dispose();
    _doc.dispose();
    super.dispose();
  }

  Future<void> _carregarEnderecos() async {
    setState(() => _carregandoEnderecos = true);
    final provider = context.read<ClienteProvider>();
    final list = await provider.listarEnderecos(widget.cliente.id);
    if (!mounted) return;
    setState(() {
      _enderecos = list;
      _carregandoEnderecos = false;
    });
  }

  Future<void> _salvar() async {
    if (_nome.text.trim().isEmpty || _telefone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome e telefone sao obrigatorios')));
      return;
    }
    setState(() => _salvando = true);
    final provider = context.read<ClienteProvider>();
    final ok = await provider.updateCliente(
      widget.cliente.id,
      nome: _nome.text.trim(),
      telefone: _telefone.text.trim(),
      nomePerfil: _nomePerfil.text.trim(),
      email: _email.text.trim(),
      inscricaoFederal: _doc.text.trim(),
    );
    if (!mounted) return;
    setState(() => _salvando = false);
    if (ok == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Erro ao salvar')));
      return;
    }
    setState(() => _editando = false);
    widget.onSaved();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Cliente atualizado'), behavior: SnackBarBehavior.floating));
  }

  Future<void> _adicionarEndereco() async {
    final criado = await showEnderecoFormDialog(context, clienteId: widget.cliente.id);
    if (!mounted) return;
    if (criado != null) await _carregarEnderecos();
  }

  Future<void> _editarEndereco(EnderecoModel e) async {
    final atualizado = await showEnderecoFormDialog(context, clienteId: widget.cliente.id, endereco: e);
    if (!mounted) return;
    if (atualizado != null) await _carregarEnderecos();
  }

  Future<void> _excluirEndereco(EnderecoModel e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover endereco?'),
        content: Text(e.enderecoCompleto),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirm != true) return;
    final provider = context.read<ClienteProvider>();
    final ok = await provider.excluirEndereco(widget.cliente.id, e.id);
    if (!mounted) return;
    if (ok) {
      await _carregarEnderecos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Erro ao remover')));
    }
  }

  Future<void> _definirPrincipal(EnderecoModel e) async {
    final provider = context.read<ClienteProvider>();
    final ok = await provider.definirEnderecoPrincipal(widget.cliente.id, e.id);
    if (!mounted) return;
    if (ok) await _carregarEnderecos();
  }

  @override
  Widget build(BuildContext context) {
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
          _campo('Telefone', _telefone, editando: _editando),
          _campo('Nome do perfil', _nomePerfil, editando: _editando),
          _campo('E-mail', _email, editando: _editando),
          _campo('CPF / CNPJ', _doc, editando: _editando),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Enderecos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              FilledButton.icon(
                onPressed: _adicionarEndereco,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_carregandoEnderecos)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_enderecos.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Center(
                child: Text('Nenhum endereco cadastrado', style: TextStyle(color: AppColors.textGrey)),
              ),
            )
          else
            ..._enderecos.map(
              (e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: e.principal ? AppColors.accent : AppColors.borderLight,
                    width: e.principal ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          e.principal ? Icons.star : Icons.location_on_outlined,
                          size: 16,
                          color: e.principal ? AppColors.accent : AppColors.textGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(e.tipo.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                        const Spacer(),
                        if (!e.principal)
                          IconButton(
                            tooltip: 'Marcar como principal',
                            icon: const Icon(Icons.star_border, size: 18),
                            onPressed: () => _definirPrincipal(e),
                          ),
                        IconButton(
                          tooltip: 'Editar',
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _editarEndereco(e),
                        ),
                        IconButton(
                          tooltip: 'Remover',
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          onPressed: () => _excluirEndereco(e),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(e.enderecoCompleto, style: const TextStyle(fontSize: 13)),
                    if (e.referencia != null && e.referencia!.isNotEmpty)
                      Text(
                        'Ref: ${e.referencia}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                _info('Criado em', DateFormat('dd/MM/yyyy HH:mm').format(widget.cliente.createdAt)),
                _info('Atualizado em', DateFormat('dd/MM/yyyy HH:mm').format(widget.cliente.updatedAt)),
                if (widget.cliente.ultimoPedidoAt != null)
                  _info('Ultimo pedido', DateFormat('dd/MM/yyyy').format(widget.cliente.ultimoPedidoAt!)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl, {required bool editando}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        enabled: editando,
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
