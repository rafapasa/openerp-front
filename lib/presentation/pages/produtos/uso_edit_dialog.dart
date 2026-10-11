import 'package:flutter/material.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/services/uso_service.dart';
import 'package:front_openerp/presentation/theme/app_colors.dart';
import 'package:provider/provider.dart';

Future<UsoModel?> showUsoEditDialog(BuildContext context, {UsoModel? uso}) {
  final service = context.read<UsoService>();
  return showDialog<UsoModel>(
    context: context,
    builder: (_) => UsoEditDialog(uso: uso, service: service),
  );
}

class UsoEditDialog extends StatefulWidget {
  final UsoModel? uso;
  final UsoService service;
  const UsoEditDialog({super.key, this.uso, required this.service});

  @override
  State<UsoEditDialog> createState() => _UsoEditDialogState();
}

class _UsoEditDialogState extends State<UsoEditDialog> {
  late final TextEditingController _label;
  late final TextEditingController _sinonimos;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.uso?.label ?? '');
    _sinonimos = TextEditingController(text: widget.uso?.sinonimos ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    _sinonimos.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final label = _label.text.trim();
    if (label.isEmpty) {
      setState(() => _erro = 'Informe o nome do uso');
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final UsoModel saved;
      if (widget.uso == null) {
        saved = await widget.service.criar(label: label, sinonimos: _sinonimos.text.trim());
      } else {
        saved = await widget.service.atualizar(widget.uso!.id, label: label, sinonimos: _sinonimos.text.trim());
      }
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final criando = widget.uso == null;
    return AlertDialog(
      title: Text(criando ? 'Adicionar uso' : 'Editar uso'),
      content: SizedBox(
        width: 468,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _label,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _sinonimos,
              minLines: 3,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Sinonimos',
                hintText: 'gripe, resfriado, coriza, febre',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_erro!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _salvando ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _salvando ? null : _salvar, child: Text(criando ? 'Criar' : 'Salvar')),
      ],
    );
  }
}
