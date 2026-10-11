import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:front_openerp/presentation/widgets/app_section_card.dart';
import 'package:front_openerp/presentation/widgets/viewport_box.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';

Future<EnderecoModel?> showEnderecoFormDialog(BuildContext context, {required int clienteId, EnderecoModel? endereco}) {
  return showDialog<EnderecoModel>(
    context: context,
    barrierDismissible: false,
    builder: (_) => EnderecoFormDialog(clienteId: clienteId, endereco: endereco),
  );
}

class EnderecoFormDialog extends StatefulWidget {
  final int clienteId;
  final EnderecoModel? endereco;
  const EnderecoFormDialog({super.key, required this.clienteId, this.endereco});

  @override
  State<EnderecoFormDialog> createState() => _EnderecoFormDialogState();
}

class _EnderecoFormDialogState extends State<EnderecoFormDialog> {
  final _cep = TextEditingController();
  final _logradouro = TextEditingController();
  final _numero = TextEditingController();
  final _complemento = TextEditingController();
  final _bairro = TextEditingController();
  final _cidade = TextEditingController();
  final _estado = TextEditingController();
  final _referencia = TextEditingController();
  String _tipo = 'entrega';
  bool _principal = false;
  bool _saving = false;
  bool _buscandoCep = false;

  bool get _editando => widget.endereco != null;

  @override
  void initState() {
    super.initState();
    final e = widget.endereco;
    if (e != null) {
      _cep.text = e.cep;
      _logradouro.text = e.logradouro;
      _numero.text = e.numero;
      _complemento.text = e.complemento ?? '';
      _bairro.text = e.bairro;
      _cidade.text = e.cidade;
      _estado.text = e.estado;
      _referencia.text = e.referencia ?? '';
      _tipo = e.tipo;
      _principal = e.principal;
    }
  }

  @override
  void dispose() {
    for (final c in [_cep, _logradouro, _numero, _complemento, _bairro, _cidade, _estado, _referencia]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _buscarCep() async {
    final cep = _cep.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CEP deve ter 8 digitos')));
      return;
    }
    setState(() => _buscandoCep = true);
    try {
      final res = await Dio().get('https://viacep.com.br/ws/$cep/json/');
      final data = res.data;
      if (data is Map && data['erro'] == true) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CEP nao encontrado')));
        return;
      }
      if (data is Map) {
        setState(() {
          _logradouro.text = '${data['logradouro'] ?? ''}';
          _bairro.text = '${data['bairro'] ?? ''}';
          _cidade.text = '${data['localidade'] ?? ''}';
          _estado.text = '${data['uf'] ?? ''}';
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao consultar o CEP')));
      }
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _salvar() async {
    if (_logradouro.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logradouro e obrigatorio')));
      return;
    }
    if (_numero.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numero e obrigatorio')));
      return;
    }
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'cep': _cep.text.replaceAll(RegExp(r'\D'), ''),
      'logradouro': _logradouro.text.trim(),
      'numero': _numero.text.trim(),
      'complemento': _complemento.text.trim(),
      'bairro': _bairro.text.trim(),
      'cidade': _cidade.text.trim(),
      'estado': _estado.text.trim(),
      'pais': 'Brasil',
      'referencia': _referencia.text.trim(),
      'tipo': _tipo,
      'principal': _principal,
    };
    final provider = context.read<ClienteProvider>();
    final result = _editando
        ? await provider.editarEndereco(widget.clienteId, widget.endereco!.id, payload)
        : await provider.criarEndereco(widget.clienteId, payload);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Erro ao salvar endereco')));
      return;
    }
    Navigator.pop(context, result);
  }

  Widget _field(
    TextEditingController c,
    String hint, {
    TextInputType? kb,
    List<TextInputFormatter>? fmt,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: TextField(
        controller: c,
        enabled: !_saving,
        keyboardType: kb,
        inputFormatters: fmt,
        decoration: InputDecoration(hintText: hint),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: caixaDaJanela(context, maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _editando ? 'Editar endereco' : 'Novo endereco',
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
                      titulo: 'Endereco',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _field(
                                _cep,
                                'CEP',
                                kb: TextInputType.number,
                                fmt: [FilteringTextInputFormatter.digitsOnly],
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: _saving || _buscandoCep ? null : _buscarCep,
                                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                                icon: _buscandoCep
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.search, size: 18),
                                label: const Text('Buscar CEP'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _field(_logradouro, 'Logradouro *', flex: 3),
                              const SizedBox(width: 8),
                              _field(_numero, 'Numero *'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(children: [_field(_complemento, 'Complemento')]),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _field(_bairro, 'Bairro'),
                              const SizedBox(width: 8),
                              _field(_cidade, 'Cidade', flex: 2),
                              const SizedBox(width: 8),
                              _field(_estado, 'UF'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(children: [_field(_referencia, 'Referencia')]),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _tipo,
                            decoration: const InputDecoration(hintText: 'Tipo'),
                            items: const [
                              DropdownMenuItem(value: 'residencial', child: Text('Residencial')),
                              DropdownMenuItem(value: 'comercial', child: Text('Comercial')),
                              DropdownMenuItem(value: 'entrega', child: Text('Entrega')),
                              DropdownMenuItem(value: 'cobranca', child: Text('Cobranca')),
                            ],
                            onChanged: _saving ? null : (v) => setState(() => _tipo = v ?? 'entrega'),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: const Text('Endereco principal'),
                            subtitle: const Text('Desmarca os outros automaticamente'),
                            value: _principal,
                            activeThumbColor: AppColors.accent,
                            onChanged: _saving ? null : (v) => setState(() => _principal = v),
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
