// lib/presentation/theme/app_colors.dart
// Tema eTools Tecnologia - OpenERP / ERPCloud
import 'package:flutter/material.dart';

abstract class AppColors {
  // Marca eTools (extraído da Logo_fundo_branco.jpg)
  static const primary = Color(0xFF184F9A); // Azul do "Tools"
  static const primaryDark = Color(0xFF0F2C5C); // Sidebar escura
  static const primaryLight = Color(0xFFE8EFFB);

  static const accent = Color(0xFF00B050); // Verde do "e" com seta
  static const accentLight = Color(0xFFE6F9EE);
  static const accentDark = Color(0xFF00913C);

  // Neutros
  static const background = Color(0xFFF4F6F8);
  static const card = Colors.white;
  static const textDark = Color(0xFF1E293B);
  static const textGrey = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const borderLight = Color(0xFFF1F5F9);

  // Status
  static const success = Color(0xFF00B050);
  static const successBg = Color(0xFFE6F9EE);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}
