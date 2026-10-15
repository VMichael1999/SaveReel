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
          title: Text(context.strings.deleteTitle),
          content: Text(
            hasGalleryCopy
                ? context.strings.deleteBodyCopy
                : context.strings.deleteBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.strings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.failed,
              ),
              child: Text(context.strings.delete),
            ),
          ],
        ),
  );
  return confirmed ?? false;
}
