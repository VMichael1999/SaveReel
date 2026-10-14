import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_enums.dart';

void showAppMessage(
  BuildContext context, {
  required String msg,
  required ToastType type,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            type == ToastType.success ? AppColors.black : AppColors.error,
      ),
    );
}
