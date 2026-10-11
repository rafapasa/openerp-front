import 'package:flutter/material.dart';
import 'package:front_openerp/core/helpers/snack_helper.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/presentation/providers/produto_provider.dart';
import 'package:front_openerp/presentation/theme/app_colors.dart';
import 'package:provider/provider.dart';

/// Linha editável em memória. `id == null` indica token novo (POST).
class _TokenRow {
  int? id;
  final TextEditingController tokenCtrl;
  ProdutoTokenOrigem origem;
  bool removido;

  _TokenRow({this.id, required String token, this.origem = ProdutoTokenOrigem.nome})
    : removido = false,
      tokenCtrl = TextEditingController(text: token);

  factory _TokenRow.fromModel(ProdutoTokenModel m) => _TokenRow(id: m.id, token: m.token, origem: m.origem);

  bool get isNovo => id == null;

  String get token => tokenCtrl.text;

  void dispose() => tokenCtrl.dispose();
}

/// Snapshot do estado original (token + origem) para calcular o diff no PUT.
class _TokenSnapshot {
  final String token;
  final ProdutoTokenOrigem origem;
  const _TokenSnapshot(this.token, this.origem);
}

class ProdutoTokenTab extends StatefulWidget {
  final int produtoId;
  const ProdutoTokenTab({super.key, required this.produtoId});

  @override
  State<ProdutoTokenTab> createState() => _ProdutoTokenTabState();
}

class _ProdutoTokenTabState extends State<ProdutoTokenTab> {
  static const double _alturaLinha = 40;

  List<_TokenRow> _rows = [];
  final Map<int, _TokenSnapshot> _originais = {};
  bool _loading = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    final list = await context.read<ProdutoProvider>().listarTokens(widget.produtoId);
    if (!mounted) return;
    for (final r in _rows) {
      r.dispose();
    }
    setState(() {
      _rows = list.map(_TokenRow.fromModel).toList();
      _loading = false;
    });
    _snapshotOriginais();
  }

  void _snapshotOriginais() {
    _originais
      ..clear()
      ..addEntries(_rows.where((r) => !r.isNovo).map((r) => MapEntry(r.id!, _TokenSnapshot(r.token, r.origem))));
  }

  bool _alterado(_TokenRow r) {
    if (r.isNovo) return false;
    final snap = _originais[r.id];
    if (snap == null) return true;
    return snap.token != r.token || snap.origem != r.origem;
  }

  void _adicionar() {
    setState(() {
      _rows.add(_TokenRow(token: '', origem: ProdutoTokenOrigem.nome));
    });
  }

  void _remover(_TokenRow row) {
    setState(() {
      if (row.isNovo) {
        _rows.remove(row);
        row.dispose();
      } else {
        row.removido = true;
      }
    });
  }

  Future<void> _salvar() async {
    // Validação: token obrigatório nas linhas ativas.
    final invalido = _rows.any((r) => !r.removido && r.token.trim().isEmpty);
    if (invalido) {
      showSavedSnack(context, message: 'Preencha o token de todas as linhas');
      return;
    }

    final novos = _rows.where((r) => !r.removido && r.isNovo).toList();
    final alterados = _rows.where((r) => !r.removido && _alterado(r)).toList();
    final removidos = _rows.where((r) => r.removido && !r.isNovo).map((r) => r.id!).toList();

    if (novos.isEmpty && alterados.isEmpty && removidos.isEmpty) {
      showSavedSnack(context, message: 'Nada para salvar');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final provider = context.read<ProdutoProvider>();
    try {
      if (novos.isNotEmpty) {
        await provider.criarTokens(
          widget.produtoId,
          novos
              .map(
                (r) => ProdutoTokenModel(id: 0, produtoId: widget.produtoId, token: r.token.trim(), origem: r.origem),
              )
              .toList(),
        );
      }
      if (alterados.isNotEmpty) {
        await provider.atualizarTokens(
          widget.produtoId,
          alterados
              .map(
                (r) =>
                    ProdutoTokenModel(id: r.id!, produtoId: widget.produtoId, token: r.token.trim(), origem: r.origem),
              )
              .toList(),
        );
      }
      if (removidos.isNotEmpty) {
        await provider.excluirTokens(widget.produtoId, removidos);
      }
      if (!mounted) return;
      showSavedSnack(context, message: 'Salvo');
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = e.toString();
      });
      showSavedSnack(context, message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    final ativos = _rows.where((r) => !r.removido).toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Tokens', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _salvando ? null : _adicionar,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _tabela(ativos),
                if (_erro != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_erro!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
        _footer(),
      ],
    );
  }

  Widget _tabela(List<_TokenRow> ativos) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalho(),
          if (ativos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Text(
                'Nenhum token. Adicione tokens para melhorar a busca deste produto.',
                style: TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
            )
          else
            ...ativos.map(_linha),
        ],
      ),
    );
  }

  Widget _cabecalho() {
    return Container(
      height: _alturaLinha,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'TOKEN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGrey,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ORIGEM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGrey,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _linha(_TokenRow row) {
    return Container(
      height: _alturaLinha,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: row.tokenCtrl,
              enabled: !_salvando,
              expands: true,
              maxLines: null,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 14, height: 1),
              decoration: const InputDecoration(
                hintText: 'Token',
                isCollapsed: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
              onChanged: (v) => row.tokenCtrl.text = v,
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1, color: AppColors.borderLight),
          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ProdutoTokenOrigem>(
                value: row.origem,
                isExpanded: true,
                isDense: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                items: ProdutoTokenOrigem.values.map((o) => DropdownMenuItem(value: o, child: Text(o.label))).toList(),
                onChanged: _salvando ? null : (v) => setState(() => row.origem = v ?? ProdutoTokenOrigem.nome),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Center(
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Remover',
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                onPressed: _salvando ? null : () => _remover(row),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton.icon(
            onPressed: _salvando ? null : _salvar,
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            icon: _salvando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
