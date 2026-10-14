import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import '../../config/theme/app_tokens.dart';
import '../utils/app_enums.dart';
import 'savetic_toast.dart';

/// Muestra un aviso arriba de la pantalla. Reemplaza al anterior si lo hay,
/// y no tapa los botones de abajo.
void showAppMessage(
  BuildContext context, {
  required String msg,
  required MessageType type,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);

  _haptic(type);
  toastification.dismissAll(delayForAnimation: false);
  toastification.showCustom(
    context: context,
    alignment: Alignment.topCenter,
    animationDuration: reduceMotion ? Duration.zero : AppMotion.slow,
    autoCloseDuration: _durationFor(type, hasAction: actionLabel != null),
    animationBuilder:
        (context, animation, alignment, child) =>
            reduceMotion ? child : _slideFromTop(animation, child),
    builder:
        (context, item) => SaveticToast(
          message: msg,
          type: type,
          actionLabel: actionLabel,
          onAction: onAction,
          onDismissed:
              () => toastification.dismiss(item, showRemoveAnimation: false),
        ),
  );
}

/// Los errores y los avisos con acción duran más: hay que dar tiempo a leerlos
/// o a tocar la acción.
Duration _durationFor(MessageType type, {required bool hasAction}) {
  if (hasAction) return const Duration(seconds: 6);
  return type == MessageType.error
      ? const Duration(seconds: 5)
      : const Duration(milliseconds: 3500);
}

Widget _slideFromTop(Animation<double> animation, Widget child) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: AppMotion.emphasized,
    reverseCurve: AppMotion.exit,
  );
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.6),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

/// Vibración suave: ligera para lo que salió bien, media para un error.
void _haptic(MessageType type) {
  final feedback = switch (type) {
    MessageType.success => HapticFeedback.lightImpact(),
    MessageType.error => HapticFeedback.mediumImpact(),
    MessageType.info => null,
  };
  feedback?.catchError((_) {});
}
