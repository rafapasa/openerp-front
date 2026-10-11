import 'package:flutter/material.dart';
import 'package:front_openerp/core/helpers/json_helper.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/services/api_service.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';

class _Forma {
  final int id;
  final String nome;
  _Forma(this.id, this.nome);
}

Future<bool> showPagamentoPedidoDialog(BuildContext context, PedidoModel pedido) async {
  final api = context.read<ApiService>();
  final formas = <_Forma>[];
  try {
    final res = await api.get('/formas-pagamento', queryParameters: {'limit': 50, 'ativo': 'true'});
    final list = JsonHelper.extractList(res.data);
    for (final e in list) {
      if (e is Map<String, dynamic>) {
        formas.add(_Forma(JsonHelper.toInt(e['id']), JsonHelper.toStr(e['nome'], fallback: 'Forma')));
      }
    }
  } catch (_) {}

  int? formaId = formas.isEmpty ? null : formas.first.id;
  final valorCtrl = TextEditingController(text: pedido.total.toStringAsFixed(2));

  if (!context.mounted) return false;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Receber pedido #${pedido.id}'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (formas.isEmpty)
              const Text('Nenhuma forma cadastrada. O pagamento será só marcado como pago.')
            else
              DropdownButtonFormField<int>(
                initialValue: formaId,
                decoration: const InputDecoration(hintText: 'Forma de pagamento'),
                items: formas.map((f) => DropdownMenuItem(value: f.id, child: Text(f.nome))).toList(),
                onChanged: (v) => formaId = v,
              ),
            const SizedBox(height: 8),
            TextField(
              controller: valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Valor'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Confirmar pagamento'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  final valor = double.tryParse(valorCtrl.text.replaceAll(',', '.'));
  return context.read<PedidoProvider>().marcarPago(pedido.id, formaPagamentoId: formaId, valor: valor);
}
