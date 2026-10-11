import 'package:flutter/material.dart';
import 'package:front_openerp/data/models/categoria_model.dart';
import 'package:front_openerp/data/services/categoria_service.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  final _busca = TextEditingController();
  List<CategoriaModel> _itens = [];
  bool _loading = true;

  CategoriaService get _svc => context.read<CategoriaService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _svc.list(q: _busca.text.trim());
      if (!mounted) return;
      setState(() => _itens = res.data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrir([CategoriaModel? item]) async {
    final salvo = await showDialog<bool>(
      context: context,
      builder: (_) => _CategoriaModal(item: item, service: _svc),
    );
    if (salvo == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _busca,
                decoration: const InputDecoration(hintText: 'Buscar categoria', prefixIcon: Icon(Icons.search)),
                onSubmitted: (_) => _load(),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(onPressed: () => _abrir(), icon: const Icon(Icons.add), label: const Text('Nova')),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemCount: _itens.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final c = _itens[i];
                    return Card(
                      child: ListTile(
                        title: Text(c.nome),
                        subtitle: Text(c.tipoLabel),
                        trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _abrir(c)),
                        onTap: () => _abrir(c),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CategoriaModal extends StatefulWidget {
  final CategoriaModel? item;
  final CategoriaService service;
  const _CategoriaModal({required this.item, required this.service});

  @override
  State<_CategoriaModal> createState() => _CategoriaModalState();
}

class _CategoriaModalState extends State<_CategoriaModal> {
  late final TextEditingController _nome;
  late final TextEditingController _ordem;
  late String _tipo;
  late bool _ativo;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.item?.nome ?? '');
    _ordem = TextEditingController(text: '${widget.item?.ordem ?? 0}');
    _tipo = widget.item?.tipo ?? 'peca';
    _ativo = widget.item?.ativo ?? true;
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    final body = {'nome': _nome.text.trim(), 'tipo': _tipo, 'ordem': int.tryParse(_ordem.text) ?? 0, 'ativo': _ativo};
    try {
      if (widget.item == null) {
        await widget.service.create(body);
      } else {
        await widget.service.update(widget.item!.id, body);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.item == null ? 'Nova categoria' : 'Editar categoria',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nome,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(value: 'peca', child: Text('Peça')),
                      DropdownMenuItem(value: 'tinta', child: Text('Tinta')),
                      DropdownMenuItem(value: 'pneu', child: Text('Pneu')),
                      DropdownMenuItem(value: 'massa', child: Text('Massa')),
                      DropdownMenuItem(value: 'outro', child: Text('Outro')),
                    ],
                    onChanged: (v) => setState(() => _tipo = v ?? 'peca'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ordem,
                    decoration: const InputDecoration(labelText: 'Ordem'),
                    keyboardType: TextInputType.number,
                  ),
                  SwitchListTile(
                    value: _ativo,
                    onChanged: (v) => setState(() => _ativo = v),
                    title: const Text('Ativa'),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _salvando ? null : _salvar,
                    child: Text(widget.item == null ? 'Criar' : 'Salvar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
