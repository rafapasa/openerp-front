import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_section_card.dart';

Future<ClienteModel?> showNovoClienteDialog(BuildContext context, {String nomeInicial = ''}) {
  return showDialog<ClienteModel>(
    context: context,
    barrierDismissible: false,
    builder: (_) => NovoClienteDialog(nomeInicial: nomeInicial),
  );
}

class NovoClienteDialog extends StatefulWidget {
  final String nomeInicial;
  const NovoClienteDialog({super.key, this.nomeInicial = ''});

  @override
  State<NovoClienteDialog> createState() => _NovoClienteDialogState();
}

class _NovoClienteDialogState extends State<NovoClienteDialog> {
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _nomePerfil = TextEditingController();
  final _email = TextEditingController();
  final _doc = TextEditingController();
  final _cep = TextEditingController();
  final _logradouro = TextEditingController();
  final _numero = TextEditingController();
  final _complemento = TextEditingController();
  final _bairro = TextEditingController();
  final _cidade = TextEditingController();
  final _estado = TextEditingController();
  final _referencia = TextEditingController();
  String _tipo = 'residencial';
  bool _saving = false;
  bool _buscandoCep = false;

  @override
  void initState() {
    super.initState();
    _nome.text = widget.nomeInicial;
  }

  @override
  void dispose() {
    for (final c in [
      _nome,
      _telefone,
      _nomePerfil,
      _email,
      _doc,
      _cep,
      _logradouro,
      _numero,
      _complemento,
      _bairro,
      _cidade,
      _estado,
      _referencia,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _buscarCep() async {
    final cep = _cep.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CEP deve ter 8 dígitos')));
      return;
    }
    setState(() => _buscandoCep = true);
    try {
      final res = await Dio().get('https://viacep.com.br/ws/$cep/json/');
      final data = res.data;
      if (data is Map && data['erro'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CEP não encontrado')));
        }
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
    if (_nome.text.trim().isEmpty || _telefone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome e telefone são obrigatórios')));
      return;
    }
    setState(() => _saving = true);
    Map<String, dynamic>? endereco;
    if (_logradouro.text.trim().isNotEmpty || _cep.text.trim().isNotEmpty) {
      endereco = {
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
        'principal': true,
      };
    }
    final criado = await context.read<ClienteProvider>().createCliente(
      nome: _nome.text.trim(),
      telefone: _telefone.text.trim(),
      nomePerfil: _nomePerfil.text.trim(),
      email: _email.text.trim(),
      inscricaoFederal: _doc.text.trim(),
      endereco: endereco,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (criado == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.read<ClienteProvider>().error ?? 'Falha ao criar cliente')));
      return;
    }
    Navigator.pop(context, criado);
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
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Novo cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(onPressed: _saving ? null : () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              Expanded(
                child: ListView(
                  children: [
                    AppSectionCard(
                      titulo: 'Dados',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _field(_nome, 'Nome *', flex: 3),
                              const SizedBox(width: 8),
                              _field(_telefone, 'Telefone *', kb: TextInputType.phone, flex: 2),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _field(_nomePerfil, 'Nome do perfil'),
                              const SizedBox(width: 8),
                              _field(_email, 'E-mail', kb: TextInputType.emailAddress),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(children: [_field(_doc, 'CPF / CNPJ')]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppSectionCard(
                      titulo: 'Endereço',
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
                              _field(_logradouro, 'Logradouro', flex: 3),
                              const SizedBox(width: 8),
                              _field(_numero, 'Número'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _field(_complemento, 'Complemento'),
                              const SizedBox(width: 8),
                              _field(_bairro, 'Bairro'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _field(_cidade, 'Cidade', flex: 2),
                              const SizedBox(width: 8),
                              _field(_estado, 'UF'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(children: [_field(_referencia, 'Referência')]),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _tipo,
                            decoration: const InputDecoration(hintText: 'Tipo'),
                            items: const [
                              DropdownMenuItem(value: 'residencial', child: Text('Residencial')),
                              DropdownMenuItem(value: 'comercial', child: Text('Comercial')),
                              DropdownMenuItem(value: 'entrega', child: Text('Entrega')),
                            ],
                            onChanged: _saving ? null : (v) => setState(() => _tipo = v ?? 'residencial'),
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
                      : const Text('Criar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
