import 'package:flutter/material.dart';
import 'package:front_openerp/presentation/widgets/viewport_box.dart';
import 'package:front_openerp/core/helpers/snack_helper.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:front_openerp/presentation/theme/app_colors.dart';
import 'package:front_openerp/presentation/pages/produtos/produto_token_tab.dart';
import 'package:front_openerp/presentation/pages/produtos/uso_nn_combo.dart';
import 'package:front_openerp/presentation/widgets/app_section_card.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<void> showProdutoDetalheModal(BuildContext context, int produtoId) {
  final isWide = MediaQuery.of(context).size.width >= 720;
  if (isWide) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: caixaDaJanela(context, maxWidth: 640),
          child: ProdutoDetalheModal(produtoId: produtoId),
        ),
      ),
    );
  }
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.92,
      child: ProdutoDetalheModal(produtoId: produtoId),
    ),
  );
}

class ProdutoDetalheModal extends StatefulWidget {
  final int produtoId;
  const ProdutoDetalheModal({super.key, required this.produtoId});

  @override
  State<ProdutoDetalheModal> createState() => _ProdutoDetalheModalState();
}

class _ProdutoDetalheModalState extends State<ProdutoDetalheModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  ProdutoModel? _produto;
  bool _loading = true;
  bool _salvando = false;
  bool _editando = false;
  String? _error;

  late TextEditingController _nome;
  late TextEditingController _descricao;
  late TextEditingController _preco;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_produto != null) {
      _nome.dispose();
      _descricao.dispose();
      _preco.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final provider = context.read<ProdutoProvider>();
    final fetched = await provider.getProdutoById(widget.produtoId);
    if (!mounted) return;
    setState(() {
      _produto = fetched;
      _loading = false;
      if (_produto == null) _error = provider.error ?? 'Produto nao encontrado';
    });
    if (_produto != null) _iniciarControllers();
  }

  void _iniciarControllers() {
    final p = _produto;
    if (p == null) return;
    _nome = TextEditingController(text: p.nome);
    _descricao = TextEditingController(text: p.descricao ?? '');
    _preco = TextEditingController(text: p.preco.toStringAsFixed(2).replaceAll('.', ','));
  }

  Future<void> _salvar() async {
    if (_nome.text.trim().isEmpty) {
      showSavedSnack(context, message: 'Nome e obrigatorio');
      return;
    }
    final preco = double.tryParse(_preco.text.replaceAll(',', '.'));
    if (preco == null || preco <= 0) {
      showSavedSnack(context, message: 'Preco invalido');
      return;
    }

    setState(() => _salvando = true);
    final provider = context.read<ProdutoProvider>();
    final ok = await provider.updateProduto(
      widget.produtoId,
      nome: _nome.text.trim(),
      preco: preco,
      descricao: _descricao.text.trim(),
      categoriaId: _produto?.categoriaId,
    );
    if (!mounted) return;
    setState(() => _salvando = false);
    if (ok == null) {
      showSavedSnack(context, message: provider.error ?? 'Erro ao salvar');
      return;
    }
    setState(() {
      _produto = ok;
      _editando = false;
    });
    showSavedSnack(context, message: 'Salvo');
  }

  Future<void> _toggleDisponivel(bool valor) async {
    final provider = context.read<ProdutoProvider>();
    final ok = await provider.toggleDisponibilidade(widget.produtoId, valor);
    if (!mounted) return;
    if (ok) {
      setState(() => _produto = _produto?.copyWith(disponivel: valor));
      showSavedSnack(context, message: 'Salvo');
    } else {
      showSavedSnack(context, message: provider.error ?? 'Erro ao alterar');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          _header(),
          if (!_loading && _error == null && _produto != null)
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textGrey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Dados'),
                Tab(icon: Icon(Icons.tag, size: 18), text: 'Tokens'),
              ],
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                ? Center(child: Text(_error!))
                : _produto == null
                ? const Center(child: Text('Produto nao encontrado'))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _dadosTab(),
                      ProdutoTokenTab(produtoId: widget.produtoId),
                    ],
                  ),
          ),
          if (!_loading && _error == null && _produto != null) _footerAcoes(),
        ],
      ),
    );
  }

  Widget _header() {
    final p = _produto;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p?.nome ?? 'Produto #${widget.produtoId}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                if (p != null) Text(p.precoFormatado, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          if (p != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: p.disponivel ? AppColors.successBg : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                p.disponivel ? 'Disponivel' : 'Indisponivel',
                style: TextStyle(
                  color: p.disponivel ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  Widget _card({required String titulo, required Widget child}) {
    return AppSectionCard(titulo: titulo, child: child);
  }

  Widget _dadosTab() {
    final p = _produto!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      children: [
        _card(
          titulo: 'Informacoes',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  if (!_editando)
                    TextButton.icon(
                      onPressed: () => setState(() => _editando = true),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Editar'),
                    )
                  else ...[
                    TextButton(
                      onPressed: _salvando
                          ? null
                          : () {
                              _iniciarControllers();
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
                ],
              ),
              const SizedBox(height: 8),
              _campo('Nome', _nome, editando: _editando),
              _campo('Descricao', _descricao, editando: _editando, maxLines: 2),
              _campo('Preco (R\$)', _preco, editando: _editando, kb: TextInputType.number),
              UsoNnCombo(
                produtoId: p.id,
                selecionados: p.usos,
                onProdutoAtualizado: (atualizado) => setState(() => _produto = atualizado),
              ),
              if (p.categoriaNome != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.category_outlined, size: 18, color: AppColors.textGrey),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: Text(
                        'Categoria',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
                      ),
                    ),
                    Expanded(
                      child: Text(p.categoriaNome!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _card(
          titulo: 'Disponibilidade',
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Disponivel', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Aparece no cardapio', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
            value: p.disponivel,
            activeThumbColor: AppColors.accent,
            onChanged: (v) => _toggleDisponivel(v),
          ),
        ),
        const SizedBox(height: 10),
        _card(
          titulo: 'Informacoes',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _info('Criado em', dateFormat.format(p.createdAt)),
              _info('Atualizado em', dateFormat.format(p.updatedAt)),
              if (p.tenantId != null) _info('Tenant ID', p.tenantId.toString()),
            ],
          ),
        ),
        if (_salvando) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
      ],
    );
  }

  Widget _campo(
    String label,
    TextEditingController ctrl, {
    required bool editando,
    int maxLines = 1,
    TextInputType? kb,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        enabled: editando,
        maxLines: maxLines,
        keyboardType: kb,
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

  Widget _footerAcoes() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_produto != null && _produto!.disponivel)
            OutlinedButton.icon(
              onPressed: _salvando ? null : () => _toggleDisponivel(false),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              icon: const Icon(Icons.block, size: 18),
              label: const Text('Marcar indisponivel'),
            )
          else if (_produto != null)
            FilledButton.icon(
              onPressed: _salvando ? null : () => _toggleDisponivel(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Marcar disponivel'),
            ),
        ],
      ),
    );
  }
}
