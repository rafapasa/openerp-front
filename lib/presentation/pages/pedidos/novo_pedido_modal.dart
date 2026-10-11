import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_openerp/core/helpers/json_helper.dart';
import 'package:front_openerp/core/helpers/launch_url.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/services/api_service.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:front_openerp/presentation/widgets/app_section_card.dart';
import 'package:front_openerp/presentation/widgets/viewport_box.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../clientes/novo_cliente_dialog.dart';

Future<void> showNovoPedidoModal(BuildContext context) {
  return showDialog(context: context, barrierDismissible: false, builder: (_) => const NovoPedidoModal());
}

class _LinhaItem {
  ProdutoModel? produto;
  int quantidade = 1;
  final TextEditingController busca = TextEditingController();
  final TextEditingController qtd = TextEditingController(text: '1');
  final FocusNode buscaFocus = FocusNode();
  final FocusNode qtdFocus = FocusNode();

  void dispose() {
    busca.dispose();
    qtd.dispose();
    buscaFocus.dispose();
    qtdFocus.dispose();
  }
}

class NovoPedidoModal extends StatefulWidget {
  const NovoPedidoModal({super.key});

  @override
  State<NovoPedidoModal> createState() => _NovoPedidoModalState();
}

class _NovoPedidoModalState extends State<NovoPedidoModal> with SingleTickerProviderStateMixin {
  ClienteModel? _cliente;
  final _clienteBusca = TextEditingController();
  final _clienteFocus = FocusNode();
  final _obs = TextEditingController();
  final _addItemFocus = FocusNode();
  final _criarFocus = FocusNode();
  final _linhas = <_LinhaItem>[_LinhaItem()];

  Timer? _clienteDebounce;
  Timer? _produtoDebounce;
  List<ClienteModel> _clientesSugestao = [];
  int _clienteHi = 0;
  bool _saving = false;
  String _tipoEntrega = 'entrega';
  final _cardCliente = GlobalKey();
  double? _alturaModal;
  final _formas = <({int id, String nome})>[];
  int? _formaId;
  late final TabController _abas;
  final _etiqueta = TextEditingController();
  List<EnderecoModel> _enderecos = [];
  EnderecoModel? _endereco;

  @override
  void initState() {
    super.initState();
    _abas = TabController(length: 4, vsync: this);
    _abas.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _medir());
    _carregarFormas();
  }

  void _medir() {
    final box = _cardCliente.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final h = box.size.height * 3.3;
    if (_alturaModal != h) setState(() => _alturaModal = h);
  }

  Future<void> _carregarFormas() async {
    try {
      final res = await context.read<ApiService>().get(
        '/formas-pagamento',
        queryParameters: {'limit': 50, 'ativo': 'true'},
      );
      final list = JsonHelper.extractList(res.data);
      final formas = <({int id, String nome})>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          formas.add((id: JsonHelper.toInt(e['id']), nome: JsonHelper.toStr(e['nome'], fallback: 'Forma')));
        }
      }
      if (!mounted) return;
      setState(() {
        _formas
          ..clear()
          ..addAll(formas);
        _formaId = formas.isEmpty ? null : formas.first.id;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _abas.dispose();
    _clienteDebounce?.cancel();
    _produtoDebounce?.cancel();
    _clienteBusca.dispose();
    _clienteFocus.dispose();
    _obs.dispose();
    _etiqueta.dispose();
    _addItemFocus.dispose();
    _criarFocus.dispose();
    for (final l in _linhas) {
      l.dispose();
    }
    super.dispose();
  }

  double get _total {
    var t = 0.0;
    for (final l in _linhas) {
      if (l.produto != null) t += l.produto!.preco * l.quantidade;
    }
    return t;
  }

  void _onClienteChanged(String raw) {
    _clienteDebounce?.cancel();
    final q = raw.trim();
    if (_cliente != null && q != _cliente!.nome) _cliente = null;
    if (q.length < 3) {
      setState(() {
        _clientesSugestao = [];
        _clienteHi = 0;
      });
      return;
    }
    _clienteDebounce = Timer(const Duration(milliseconds: 280), () async {
      await context.read<ClienteProvider>().searchByNome(q);
      if (!mounted) return;
      setState(() {
        _clientesSugestao = context.read<ClienteProvider>().clientes;
        _clienteHi = 0;
      });
    });
  }

  Future<void> _carregarEnderecos(int clienteId) async {
    setState(() {
      _enderecos = [];
      _endereco = null;
    });
    final list = await context.read<ClienteProvider>().listarEnderecos(clienteId);
    if (!mounted) return;
    setState(() {
      _enderecos = list;
      _endereco = list
          .where((e) => e.principal)
          .cast<EnderecoModel?>()
          .firstWhere((_) => true, orElse: () => list.isEmpty ? null : list.first);
    });
    if (list.isEmpty) {
      _novoEndereco();
    } else if (list.length > 1) {
      _escolherEndereco();
    }
  }

  void _pickCliente(ClienteModel c) {
    setState(() {
      _cliente = c;
      _clienteBusca.text = c.nome;
      _clientesSugestao = [];
      if (_etiqueta.text.trim().isEmpty) _etiqueta.text = c.nome;
    });
    _carregarEnderecos(c.id);
    if (_linhas.first.buscaFocus.canRequestFocus) {
      _linhas.first.buscaFocus.requestFocus();
    }
  }

  KeyEventResult _onClienteKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (_clientesSugestao.isEmpty) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _clienteHi = (_clienteHi + 1) % _clientesSugestao.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _clienteHi = (_clienteHi - 1 + _clientesSugestao.length) % _clientesSugestao.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _pickCliente(_clientesSugestao[_clienteHi]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _criarCliente() async {
    final criado = await showNovoClienteDialog(context, nomeInicial: _clienteBusca.text.trim());
    if (!mounted || criado == null) return;
    _pickCliente(criado);
  }

  Future<void> _criar() async {
    final auth = context.read<AuthProvider>();
    final balcaoId = auth.tenantAtivo?.clienteBalcaoId;
    if (_tipoEntrega != 'presencial' && _cliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione ou crie um cliente')));
      _clienteFocus.requestFocus();
      return;
    }
    if (_tipoEntrega == 'presencial' && _cliente == null && (balcaoId == null || balcaoId == 0)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tenant sem cliente Balcão. Rode o migrate da API.')));
      return;
    }
    if (_tipoEntrega == 'entrega' && _endereco == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirme o endereço de entrega')));
      return;
    }
    final itens = <Map<String, dynamic>>[];
    for (final l in _linhas) {
      final p = l.produto;
      if (p == null || l.quantidade < 1) continue;
      itens.add({'produto_id': p.id, 'nome': p.nome, 'quantidade': l.quantidade, 'preco': p.preco});
    }
    if (itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicione ao menos um produto')));
      return;
    }
    setState(() => _saving = true);
    final clienteId = _cliente?.id ?? balcaoId!;
    final nome = _cliente?.nome ?? 'Balcão';
    final fone = _cliente?.telefone ?? '';
    final etiqueta = _etiqueta.text.trim().isNotEmpty
        ? _etiqueta.text.trim()
        : (_tipoEntrega == 'presencial' ? nome : '');
    final criado = await context.read<PedidoProvider>().createPedido(
      clienteId: clienteId,
      clienteNome: nome,
      clienteTelefone: fone,
      itens: itens,
      observacoes: _obs.text,
      enderecoEntregaId: _tipoEntrega == 'entrega' ? _endereco?.id : null,
      origem: _tipoEntrega == 'presencial' ? 'presencial' : 'dashboard',
      etiqueta: etiqueta,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (criado == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.read<PedidoProvider>().error ?? 'Falha ao criar pedido')));
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido #${criado.id} criado'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    context.read<DashboardProvider>().refreshDashboard();
  }

  Future<void> _escolherEndereco() async {
    if (_cliente == null) return;
    final escolhido = await showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Escolha o endereço', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                SizedBox(
                  height: (_enderecos.length * 58.0).clamp(58.0, 320.0),
                  child: ListView.separated(
                    itemCount: _enderecos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final e = _enderecos[i];
                      return Material(
                        color: Colors.white,
                        child: InkWell(
                          onTap: () => Navigator.pop(ctx, e.id),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${e.logradouro}, ${e.numero}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                                Text(
                                  '${e.bairro} — ${e.cidade}/${e.estado}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx, -1),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Novo'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || escolhido == null) return;
    if (escolhido == -1) {
      await _novoEndereco();
      return;
    }
    setState(
      () => _endereco = _enderecos.cast<EnderecoModel?>().firstWhere((e) => e?.id == escolhido, orElse: () => null),
    );
  }

  Future<void> _novoEndereco() async {
    final cliente = _cliente;
    if (cliente == null) return;
    final cep = TextEditingController();
    final rua = TextEditingController();
    final numero = TextEditingController();
    final bairro = TextEditingController();
    final comp = TextEditingController();
    final cidade = TextEditingController();
    final uf = TextEditingController();
    var buscando = false;
    InputDecoration dec(String hint) => const InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ).copyWith(hintText: hint);
    final criado = await showDialog<EnderecoModel>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Future<void> buscar() async {
            final n = cep.text.replaceAll(RegExp(r'\D'), '');
            if (n.length != 8) return;
            setLocal(() => buscando = true);
            try {
              final res = await Dio().get('https://viacep.com.br/ws/$n/json/');
              final data = res.data;
              if (data is Map && data['erro'] != true) {
                rua.text = '${data['logradouro'] ?? ''}';
                bairro.text = '${data['bairro'] ?? ''}';
                cidade.text = '${data['localidade'] ?? ''}';
                uf.text = '${data['uf'] ?? ''}';
              }
            } catch (_) {}
            setLocal(() => buscando = false);
          }

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AppSectionCard(
                  titulo: 'Novo endereço',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 150,
                          child: TextField(
                            controller: cep,
                            decoration: dec('CEP'),
                            keyboardType: TextInputType.number,
                            onChanged: (_) {
                              if (cep.text.replaceAll(RegExp(r'\D'), '').length == 8) buscar();
                            },
                          ),
                        ),
                      ),
                      if (buscando) const LinearProgressIndicator(minHeight: 2),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 85,
                            child: TextField(controller: cidade, decoration: dec('Cidade')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 15,
                            child: TextField(controller: uf, decoration: dec('UF')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(controller: rua, decoration: dec('Rua')),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 15,
                            child: TextField(controller: numero, decoration: dec('Número')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 85,
                            child: TextField(controller: bairro, decoration: dec('Bairro')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(controller: comp, decoration: dec('Complemento')),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () async {
                              final payload = {
                                'cep': cep.text.replaceAll(RegExp(r'\D'), ''),
                                'logradouro': rua.text.trim(),
                                'numero': numero.text.trim(),
                                'bairro': bairro.text.trim(),
                                'complemento': comp.text.trim(),
                                'cidade': cidade.text.trim(),
                                'estado': uf.text.trim(),
                              };
                              final e = await context.read<ClienteProvider>().criarEndereco(cliente.id, payload);
                              if (ctx.mounted) Navigator.pop(ctx, e);
                            },
                            child: const Text('Salvar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    cep.dispose();
    rua.dispose();
    numero.dispose();
    bairro.dispose();
    comp.dispose();
    cidade.dispose();
    uf.dispose();
    if (!mounted || criado == null) return;
    setState(() {
      _enderecos = [..._enderecos, criado];
      _endereco = criado;
    });
  }

  Future<void> _abrirItem() async {
    final busca = TextEditingController();
    final qtd = TextEditingController(text: '1');
    final qtdFocus = FocusNode();
    ProdutoModel? escolhido;
    Timer? debounce;
    var sugestoes = <ProdutoModel>[];
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return Dialog(
            child: ConstrainedBox(
              constraints: caixaDaJanela(ctx, maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Adicionar item', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      autofocus: true,
                      controller: busca,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Buscar produto (3+ letras)',
                        prefixIcon: Icon(Icons.search, size: 18),
                      ),
                      onChanged: (v) {
                        debounce?.cancel();
                        if (v.trim().length < 3) {
                          setLocal(() => sugestoes = []);
                          return;
                        }
                        debounce = Timer(const Duration(milliseconds: 280), () async {
                          await context.read<ProdutoProvider>().searchByNome(v.trim());
                          if (!ctx.mounted) return;
                          setLocal(() => sugestoes = context.read<ProdutoProvider>().produtos);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: sugestoes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final p = sugestoes[i];
                          final on = escolhido?.id == p.id;
                          return Material(
                            color: on ? AppColors.accent.withValues(alpha: 0.12) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              title: Text(p.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: Text(p.precoFormatado),
                              onTap: () {
                                setLocal(() => escolhido = p);
                                qtdFocus.requestFocus();
                                qtd.selection = TextSelection(baseOffset: 0, extentOffset: qtd.text.length);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: qtd,
                      focusNode: qtdFocus,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(isDense: true, hintText: 'Quantidade'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: escolhido == null
                              ? null
                              : () {
                                  final linha = _LinhaItem();
                                  linha.produto = escolhido;
                                  linha.busca.text = escolhido!.nome;
                                  linha.quantidade = int.tryParse(qtd.text) ?? 1;
                                  linha.qtd.text = '${linha.quantidade}';
                                  setState(() {
                                    if (_linhas.length == 1 && _linhas.first.produto == null) _linhas.clear();
                                    _linhas.add(linha);
                                  });
                                  Navigator.pop(ctx);
                                },
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    debounce?.cancel();
    busca.dispose();
    qtd.dispose();
    qtdFocus.dispose();
  }

  Widget _sideBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 108,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          side: BorderSide(color: color.withValues(alpha: 0.35)),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _abaCliente() {
    final c = _cliente;
    final e = _endereco;
    final linha = e == null ? 'Endereço não informado' : '${e.logradouro}, ${e.numero}';
    final cidade = e == null ? '' : '${e.cidade} / ${e.estado}';
    final fone = (c?.telefone ?? '').replaceAll(RegExp(r'\D'), '');
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Text('Etiqueta', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _etiqueta,
                decoration: const InputDecoration(isDense: true, hintText: 'Etiqueta'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _tipoChip('Entrega', 'entrega'),
            _tipoChip('Retirada', 'retirada'),
            _tipoChip('Balcão', 'presencial'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Focus(
                onKeyEvent: _onClienteKey,
                child: TextField(
                  controller: _clienteBusca,
                  focusNode: _clienteFocus,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Buscar cliente (3+ letras)',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                  onChanged: _onClienteChanged,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _btnAzul(Icons.person_add, 'Novo Cliente', _saving ? null : _criarCliente),
          ],
        ),
        if (_clientesSugestao.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Column(
              children: [
                for (var i = 0; i < _clientesSugestao.take(6).length; i++)
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    selected: i == _clienteHi,
                    selectedTileColor: AppColors.accent.withValues(alpha: 0.12),
                    title: Text(
                      '${_clientesSugestao[i].nome}   ${_clientesSugestao[i].telefone}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    onTap: () => _pickCliente(_clientesSugestao[i]),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        AppSectionCard(
          key: _cardCliente,
          titulo: 'Cliente',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c?.nome ?? 'Cliente não selecionado',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(linha, style: const TextStyle(fontSize: 15)),
                    if (cidade.isNotEmpty)
                      Text(cidade, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                  ],
                ),
              ),
              Column(
                children: [
                  _sideBtn(Icons.call, 'Ligar', AppColors.primary, () {
                    if (fone.isNotEmpty) openExternalUrl('tel:+$fone');
                  }),
                  const SizedBox(height: 6),
                  _sideBtn(Icons.chat, 'WhatsApp', const Color(0xFF25D366), () {
                    if (fone.isNotEmpty) openExternalUrl('https://wa.me/$fone');
                  }),
                  const SizedBox(height: 6),
                  _sideBtn(Icons.map_outlined, 'Maps', const Color(0xFFEA4335), () {
                    if (e == null) return;
                    openExternalUrl(
                      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${e.logradouro}, ${e.numero}, ${e.cidade}')}',
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _btnAzul(Icons.fact_check_outlined, 'Escolher Endereço', c == null ? null : _escolherEndereco),
            const SizedBox(width: 8),
            _btnAzul(Icons.add_location_alt_outlined, 'Incluir Endereço', c == null ? null : _novoEndereco),
          ],
        ),
      ],
    );
  }

  Widget _btnAzul(IconData icon, String label, VoidCallback? onPressed) {
    return SizedBox(
      height: 40,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          visualDensity: VisualDensity.compact,
        ),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }

  Widget _tipoChip(String label, String valor) {
    final on = _tipoEntrega == valor;
    return InkWell(
      onTap: _saving ? null : () => setState(() => _tipoEntrega = valor),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary, width: on ? 1.6 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(on ? Icons.check_circle : Icons.circle_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: AppColors.primary, fontWeight: on ? FontWeight.w800 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaItens({required bool remover}) {
    final itens = _linhas.where((l) => l.produto != null).toList();
    return SizedBox(
      height: (itens.length * 28.0).clamp(28.0, 180.0),
      child: ListView(
        children: [
          for (final l in itens)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('${l.quantidade}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                  Expanded(
                    child: Text(
                      l.produto!.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(l.produto!.preco.toStringAsFixed(2), style: const TextStyle(fontSize: 13)),
                  if (remover)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: const Icon(Icons.remove_circle_outline, size: 16),
                      onPressed: () => setState(() {
                        l.dispose();
                        _linhas.remove(l);
                        if (_linhas.isEmpty) _linhas.add(_LinhaItem());
                      }),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _abaItens() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AppSectionCard(titulo: 'Itens', child: _listaItens(remover: true)),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: _btnAzul(Icons.add, 'Item', _saving ? null : _abrirItem)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total  R\$ ${_total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _abaPagamento() {
    final nome = _formas.where((f) => f.id == _formaId).map((f) => f.nome).firstOrNull ?? '';
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Pagamento', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: _formaId,
          decoration: const InputDecoration(isDense: true),
          items: [for (final f in _formas) DropdownMenuItem(value: f.id, child: Text(f.nome))],
          onChanged: (v) => setState(() => _formaId = v),
        ),
        if (_formas.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 6), child: Text('Nenhuma forma cadastrada para esta empresa.')),
        const SizedBox(height: 12),
        const Text('Observações', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        TextField(
          controller: _obs,
          maxLines: 3,
          decoration: const InputDecoration(isDense: true, hintText: 'Observações do pedido'),
        ),
        if (nome.isNotEmpty) const SizedBox(height: 0),
      ],
    );
  }

  Widget _abaGeral() {
    _linhas.where((l) => l.produto != null).toList();
    final e = _endereco;
    final forma = _formas.where((f) => f.id == _formaId).map((f) => f.nome).firstOrNull ?? '';
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          'Cliente',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textGrey),
        ),
        Text(_cliente?.nome ?? 'Balcão', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        Text(e == null ? _tipoEntrega : '${e.logradouro}, ${e.numero}', style: const TextStyle(fontSize: 13)),
        if (e != null)
          Text('${e.cidade} / ${e.estado}', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        const Divider(),
        Text(
          'Itens',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textGrey),
        ),
        _listaItens(remover: false),
        const Divider(),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total  R\$ ${_total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
        if (forma.isNotEmpty) Text(forma, style: const TextStyle(fontSize: 13)),
        if (_obs.text.trim().isNotEmpty)
          Text(_obs.text.trim(), style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final etiqueta = _etiqueta.text.trim().isEmpty ? (_cliente?.nome ?? '') : _etiqueta.text.trim();
    final altura = _alturaModal ?? 480;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 720, maxHeight: altura, minHeight: altura),
        child: Column(
          children: [
            Container(
              color: const Color(0xFFE8EEF4),
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      etiqueta.isEmpty ? 'Novo pedido' : 'Novo pedido · $etiqueta',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(onPressed: _saving ? null : () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            TabBar(
              controller: _abas,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textGrey,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              tabs: const [
                Tab(text: 'Cliente'),
                Tab(text: 'Itens'),
                Tab(text: 'Pagamento'),
                Tab(text: 'Geral'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _abas,
                children: [_abaCliente(), _abaItens(), _abaPagamento(), _abaGeral()],
              ),
            ),
            Container(
              color: const Color(0xFFE8EEF4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    focusNode: _criarFocus,
                    onPressed: _saving
                        ? null
                        : () {
                            if (_abas.index < 3) {
                              _abas.animateTo(_abas.index + 1);
                              return;
                            }
                            final forma = _formas.where((f) => f.id == _formaId).map((f) => f.nome).firstOrNull ?? '';
                            if (forma.isNotEmpty && !_obs.text.contains('Pagamento:')) {
                              _obs.text = 'Pagamento: $forma\n${_obs.text}'.trim();
                            }
                            _criar();
                          },
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    icon: Icon(_abas.index < 3 ? Icons.arrow_forward : Icons.check, size: 18),
                    label: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_abas.index < 3 ? 'Avançar' : 'Criar'),
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
