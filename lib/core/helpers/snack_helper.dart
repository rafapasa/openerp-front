import 'package:flutter/material.dart';
import 'package:front_openerp/presentation/theme/app_colors.dart';

void showSavedSnack(BuildContext context, {String message = 'Salvo'}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1500),
      backgroundColor: AppColors.primaryDark.withValues(alpha: 0.92),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
