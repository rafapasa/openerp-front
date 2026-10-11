import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:front_openerp/core/helpers/json_helper.dart';
import 'package:front_openerp/data/services/api_service.dart';
import 'package:front_openerp/presentation/theme/app_colors.dart';
import 'package:provider/provider.dart';

class ContaPage extends StatefulWidget {
  const ContaPage({super.key});

  @override
  State<ContaPage> createState() => _ContaPageState();
}

class _ContaPageState extends State<ContaPage> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _celular = TextEditingController();
  final _foto = TextEditingController();
  final _senha = TextEditingController();
  final _confirma = TextEditingController();
  String _perfil = '';
  bool _verificado = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _celular.dispose();
    _foto.dispose();
    _senha.dispose();
    _confirma.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final res = await context.read<ApiService>().get('/me');
      final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _nome.text = JsonHelper.toStr(map['nome']);
        _email.text = JsonHelper.toStr(map['email']);
        _celular.text = JsonHelper.toStr(map['celular']);
        _foto.text = JsonHelper.toStr(map['foto_url']);
        _perfil = JsonHelper.toStr(map['role']);
        _verificado = JsonHelper.toBool(map['email_verificado']);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    try {
      await context.read<ApiService>().patch('/me', data: {
        'nome': _nome.text.trim(),
        'email': _email.text.trim(),
        'celular': _celular.text.trim(),
        'foto_url': _foto.text.trim(),
        if (_senha.text.isNotEmpty) 'senha': _senha.text,
        if (_confirma.text.isNotEmpty) 'senha_confirmacao': _confirma.text,
      });
      if (!mounted) return;
      _senha.clear();
      _confirma.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados salvos')));
      await _carregar();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${e.response?.data ?? e.message}')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _verificar() async {
    try {
      await context.read<ApiService>().post('/me/verificar-email');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enviamos o link para o e-mail cadastrado')));
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${e.response?.data ?? e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dados da Conta')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_foto.text.isNotEmpty)
                  Center(child: CircleAvatar(radius: 36, backgroundImage: NetworkImage(_foto.text))),
                const SizedBox(height: 12),
                TextField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome')),
                TextField(controller: _email, decoration: const InputDecoration(labelText: 'E-mail')),
                TextField(controller: _celular, decoration: const InputDecoration(labelText: 'Celular')),
                TextField(controller: _foto, decoration: const InputDecoration(labelText: 'Foto (URL)')),
                const SizedBox(height: 8),
                Text('Perfil: $_perfil', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(_verificado ? 'E-mail verificado' : 'E-mail ainda não verificado', style: TextStyle(color: _verificado ? Colors.green : AppColors.error)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: _verificar, child: const Text('Enviar verificação de e-mail')),
                ),
                TextField(controller: _senha, obscureText: true, decoration: const InputDecoration(labelText: 'Nova senha')),
                TextField(controller: _confirma, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmação de senha')),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _salvar,
                  child: Text(_saving ? 'Salvando' : 'Salvar'),
                ),
              ],
            ),
    );
  }
}
