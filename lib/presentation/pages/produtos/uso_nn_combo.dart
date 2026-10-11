import 'package:flutter/material.dart';
import 'package:front_openerp/core/helpers/snack_helper.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/services/uso_service.dart';
import 'package:front_openerp/presentation/pages/produtos/uso_edit_dialog.dart';
import 'package:front_openerp/presentation/theme/app_colors.dart';
import 'package:provider/provider.dart';

class UsoNnCombo extends StatefulWidget {
  final int produtoId;
  final List<UsoModel> selecionados;
  final ValueChanged<ProdutoModel> onProdutoAtualizado;

  const UsoNnCombo({super.key, required this.produtoId, required this.selecionados, required this.onProdutoAtualizado});

  @override
  State<UsoNnCombo> createState() => _UsoNnComboState();
}

class _UsoNnComboState extends State<UsoNnCombo> {
  final LayerLink _link = LayerLink();
  final GlobalKey _campoKey = GlobalKey();
  OverlayEntry? _overlay;
  List<UsoModel> _todos = [];
  late List<int> _selecionados;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _selecionados = widget.selecionados.map((e) => e.id).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void didUpdateWidget(covariant UsoNnCombo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selecionados != widget.selecionados) {
      _selecionados = widget.selecionados.map((e) => e.id).toList();
    }
  }

  @override
  void dispose() {
    _fechar();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final lista = await context.read<UsoService>().listar(ativo: true);
      if (!mounted) return;
      setState(() {
        _todos = lista;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  double _larguraCampo() {
    final box = _campoKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return 280;
    return box.size.width;
  }

  void _fechar() {
    _overlay?.remove();
    _overlay = null;
  }

  void _abrir() {
    if (_overlay != null) {
      _fechar();
      return;
    }
    final largura = _larguraCampo();
    _overlay = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(onTap: _fechar, behavior: HitTestBehavior.translucent),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: const Offset(0, 48),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: largura,
                  child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 280), child: _listaCombo()),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_overlay!);
  }

  Widget _listaCombo() {
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: [
        for (final uso in _todos) _item(uso),
        ListTile(
          dense: true,
          leading: const Icon(Icons.add, color: AppColors.accent),
          title: const Text(
            'Adicionar nova',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
          ),
          onTap: () async {
            _fechar();
            final criado = await showUsoEditDialog(context);
            if (criado == null) return;
            setState(() {
              _todos = [..._todos.where((u) => u.id != criado.id), criado];
            });
            await _toggle(criado.id, forcar: true);
          },
        ),
      ],
    );
  }

  Widget _item(UsoModel uso) {
    final marcado = _selecionados.contains(uso.id);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 12, right: 4),
      leading: Icon(
        marcado ? Icons.check_box : Icons.check_box_outline_blank,
        color: marcado ? AppColors.primary : AppColors.textGrey,
      ),
      title: Text(uso.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        tooltip: 'Editar',
        icon: const Icon(Icons.edit_outlined, size: 18),
        onPressed: () async {
          _fechar();
          final editado = await showUsoEditDialog(context, uso: uso);
          if (editado == null) return;
          setState(() {
            _todos = _todos.map((u) => u.id == editado.id ? editado : u).toList();
          });
        },
      ),
      onTap: () => _toggle(uso.id),
    );
  }

  Future<void> _toggle(int id, {bool forcar = false}) async {
    final next = [..._selecionados];
    if (forcar || !next.contains(id)) {
      if (!next.contains(id)) next.add(id);
    } else {
      next.remove(id);
    }
    try {
      final prod = await context.read<UsoService>().vincularProduto(widget.produtoId, next);
      if (!mounted) return;
      setState(() => _selecionados = next);
      widget.onProdutoAtualizado(prod);
      showSavedSnack(context, message: 'Salvo');
      _overlay?.markNeedsBuild();
    } catch (e) {
      if (!mounted) return;
      showSavedSnack(context, message: e.toString());
    }
  }

  String get _resumo {
    if (_selecionados.isEmpty) return 'Selecione os usos';
    final nomes = _todos.where((u) => _selecionados.contains(u.id)).map((u) => u.label).toList();
    if (nomes.isEmpty) return '${_selecionados.length} uso(s)';
    return nomes.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CompositedTransformTarget(
        key: _campoKey,
        link: _link,
        child: InkWell(
          onTap: _carregando ? null : _abrir,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Usos / necessidade',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            child: Text(_carregando ? 'Carregando...' : _resumo, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}
