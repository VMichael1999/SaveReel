import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme/app_tokens.dart';

extension EnterAnimation on Widget {
  /// Entrada suave: aparece y sube un poco. No anima si el usuario
  /// desactivó las animaciones del sistema.
  Widget enter(BuildContext context, {Duration delay = Duration.zero}) {
    if (MediaQuery.disableAnimationsOf(context)) return this;
    return animate(delay: delay)
        .fadeIn(duration: AppMotion.base, curve: AppMotion.standard)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: AppMotion.base,
          curve: AppMotion.standard,
        );
  }
}
