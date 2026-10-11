import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'viewport_box.dart';

/// Barra de título cinza igual à listagem (CLIENTE / ITENS / …).
class AppSectionCard extends StatelessWidget {
  final String titulo;
  final Widget child;
  const AppSectionCard({super.key, required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Text(
              titulo.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textGrey,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}

/// Shell de modal de edição/criação (header + body + footer com Criar/Salvar).
class AppEditModal extends StatelessWidget {
  final String titulo;
  final Widget body;
  final List<Widget> footer;
  final double maxWidth;
  final double maxHeight;

  const AppEditModal({
    super.key,
    required this.titulo,
    required this.body,
    required this.footer,
    this.maxWidth = 560,
    this.maxHeight = 720,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: caixaDaJanela(context, maxWidth: maxWidth),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: Padding(padding: const EdgeInsets.all(16), child: body),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: footer),
            ),
          ],
        ),
      ),
    );
  }
}
