import 'package:flutter/material.dart';

import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';

/// Pide confirmar antes de borrar. Devuelve `true` si el usuario acepta.
Future<bool> confirmDeleteVideo(
  BuildContext context, {
  required bool hasGalleryCopy,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text(AppStrings.deleteTitle),
          content: Text(
            hasGalleryCopy ? AppStrings.deleteBodyCopy : AppStrings.deleteBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.failed,
              ),
              child: const Text(AppStrings.delete),
            ),
          ],
        ),
  );
  return confirmed ?? false;
}
