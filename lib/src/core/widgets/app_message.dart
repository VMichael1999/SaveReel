import 'package:flutter/material.dart';

import '../../config/theme/savetic_colors.dart';
import '../utils/app_enums.dart';

void showAppMessage(
  BuildContext context, {
  required String msg,
  required MessageType type,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final colors = context.colors;
  final isError = type == MessageType.error;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style:
              isError
                  ? Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.failed)
                  : null,
        ),
        backgroundColor: isError ? colors.failedSoft : null,
        action:
            actionLabel == null
                ? null
                : SnackBarAction(
                  label: actionLabel,
                  onPressed: onAction ?? () {},
                ),
      ),
    );
}
