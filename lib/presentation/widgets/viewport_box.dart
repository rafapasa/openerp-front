import 'package:flutter/material.dart';

/// Limita um modal à janela visível. Pixel fixo só vale como teto, nunca como altura obrigatória.
BoxConstraints caixaDaJanela(BuildContext context, {double maxWidth = 640}) {
  final size = MediaQuery.sizeOf(context);
  final largura = (size.width - 48).clamp(280.0, maxWidth);
  final altura = size.height - 48;
  return BoxConstraints(maxWidth: largura, maxHeight: altura < 240 ? size.height : altura);
}
