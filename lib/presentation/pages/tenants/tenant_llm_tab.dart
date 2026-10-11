import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_openerp/core/helpers/snack_helper.dart';
import 'package:front_openerp/data/models/tenant_llm_config.dart';
import 'package:front_openerp/data/models/tenant_model.dart';
import 'package:front_openerp/presentation/providers/tenant_provider.dart';
import 'package:front_openerp/presentation/theme/app_colors.dart';
import 'package:front_openerp/presentation/widgets/app_section_card.dart';
import 'package:provider/provider.dart';

class TenantLlmTab extends StatefulWidget {
  final TenantModel tenant;
  final ValueChanged<TenantModel> onSaved;
  const TenantLlmTab({super.key, required this.tenant, required this.onSaved});

  @override
  State<TenantLlmTab> createState() => _TenantLlmTabState();
}

class _TenantLlmTabState extends State<TenantLlmTab> {
  late TextEditingController _segmento;
  late TextEditingController _videoFrame;
  late TextEditingController _videoSintese;
  late TextEditingController _visaoLista;
  late TextEditingController _transcribe;
  late TextEditingController _unidade;
  late TextEditingController _margem;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _initFrom(widget.tenant.llmConfig ?? const TenantLlmConfig());
  }

  void _initFrom(TenantLlmConfig cfg) {
    _segmento = TextEditingController(text: cfg.segmento ?? '');
    _videoFrame = TextEditingController(text: cfg.videoFrame ?? '');
    _videoSintese = TextEditingController(text: cfg.videoSintese ?? '');
    _visaoLista = TextEditingController(text: cfg.visaoLista ?? '');
    _transcribe = TextEditingController(text: cfg.transcribe ?? '');
    _unidade = TextEditingController(text: cfg.unidadeArea ?? '');
    _margem = TextEditingController(text: cfg.margemQuantidade == null ? '' : cfg.margemQuantidade.toString());
  }

  double? _parseMargem(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  TenantLlmConfig _fromFields() {
    return TenantLlmConfig(
      segmento: _segmento.text,
      videoFrame: _videoFrame.text,
      videoSintese: _videoSintese.text,
      visaoLista: _visaoLista.text,
      transcribe: _transcribe.text,
      unidadeArea: _unidade.text,
      margemQuantidade: _parseMargem(_margem.text),
    );
  }

  Future<void> _salvar() async {
    final margemTxt = _margem.text.trim();
    if (margemTxt.isNotEmpty) {
      final n = double.tryParse(margemTxt.replaceAll(',', '.'));
      if (n == null || n < 0.5 || n > 3) {
        showSavedSnack(context, message: 'Margem deve ser um numero entre 0.5 e 3');
        return;
      }
    }
    setState(() => _salvando = true);
    final provider = context.read<TenantProvider>();
    final atualizado = await provider.atualizarLlmConfig(widget.tenant.id!, _fromFields());
    if (!mounted) return;
    setState(() => _salvando = false);
    if (atualizado == null) {
      showSavedSnack(context, message: provider.error ?? 'Erro ao salvar LLM');
      return;
    }
    widget.onSaved(atualizado);
    showSavedSnack(context, message: 'Configuracao LLM salva');
  }

  void _limpar() {
    _segmento.clear();
    _videoFrame.clear();
    _videoSintese.clear();
    _visaoLista.clear();
    _transcribe.clear();
    _unidade.clear();
    _margem.clear();
    setState(() {});
  }

  @override
  void dispose() {
    _segmento.dispose();
    _videoFrame.dispose();
    _videoSintese.dispose();
    _visaoLista.dispose();
    _transcribe.dispose();
    _unidade.dispose();
    _margem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Prompts por empresa. Campo vazio usa o padrao do sistema.',
            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
          const SizedBox(height: 12),
          AppSectionCard(
            titulo: 'Segmento',
            child: Column(
              children: [
                TextField(
                  controller: _segmento,
                  decoration: const InputDecoration(
                    labelText: 'Segmento do prompt',
                    hintText: 'ex: material_construcao, eletrica, mecanica',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _unidade,
                        decoration: const InputDecoration(labelText: 'Unidade de area', hintText: 'm2'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _margem,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        decoration: const InputDecoration(labelText: 'Margem quantidade', hintText: '1.1'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppSectionCard(
            titulo: 'Prompts',
            child: Column(
              children: [
                TextField(
                  controller: _videoFrame,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Video — leitura do local',
                    hintText: 'Como a visao deve medir o ambiente',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _videoSintese,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Video — lista de materiais',
                    hintText: 'Como montar qtd + material da obra/servico',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _visaoLista,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Imagem — lista', alignLabelWithHint: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _transcribe,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Audio — transcricao', alignLabelWithHint: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(onPressed: _salvando ? null : _limpar, child: const Text('Limpar (usar padrao)')),
              const Spacer(),
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
    );
  }
}
