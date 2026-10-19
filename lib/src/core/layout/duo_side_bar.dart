import 'package:flutter/material.dart';

import '../../config/theme/app_tokens.dart';
import '../../config/theme/savetic_colors.dart';
import 'duo_layout.dart';

/// Un botón de la franja lateral.
class DuoAction {
  const DuoAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeCount = 0,
  });

  final IconData icon;

  /// Texto del `tooltip` y de la etiqueta de accesibilidad.
  final String tooltip;
  final VoidCallback? onPressed;

  /// Si es mayor que cero, se dibuja como insignia.
  final int badgeCount;
}

/// Franja de 64 pt pegada al borde derecho con las acciones de la pantalla.
///
/// Arriba deja libre el espacio de la isla y la barra de estado, que sale de
/// `MediaQuery.paddingOf`, y luego van las acciones de [top]; las de [bottom]
/// quedan pegadas al final. Con [overVideo] los botones usan el relleno de
/// los controles sobre video.
class DuoSideBar extends StatelessWidget {
  const DuoSideBar({
    super.key,
    this.top = const [],
    this.bottom = const [],
    this.overVideo = false,
  });

  final List<DuoAction> top;
  final List<DuoAction> bottom;
  final bool overVideo;

  static const double buttonSize = 44;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return SizedBox(
      width: kDuoSideBarWidth,
      child: Padding(
        padding: EdgeInsets.only(
          top: padding.top + AppSpacing.sm,
          bottom: padding.bottom + AppSpacing.sm,
        ),
        child: Column(
          children: [
            for (var i = 0; i < top.length; i++) ...[
              if (i > 0) const SizedBox(height: _gap),
              _DuoButton(action: top[i], overVideo: overVideo),
            ],
            const Spacer(),
            for (var i = 0; i < bottom.length; i++) ...[
              if (i > 0) const SizedBox(height: _gap),
              _DuoButton(action: bottom[i], overVideo: overVideo),
            ],
          ],
        ),
      ),
    );
  }
}

class _DuoButton extends StatelessWidget {
  const _DuoButton({required this.action, required this.overVideo});

  final DuoAction action;
  final bool overVideo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = overVideo ? AppOverlay.controlFill : colors.raised;
    final border = overVideo ? AppOverlay.actionFill : colors.line;
    final iconColor =
        overVideo
            ? AppOverlay.onVideo
            : Theme.of(context).colorScheme.onSurface;

    Widget icon = Icon(action.icon, size: 22, color: iconColor);
    if (action.badgeCount > 0) {
      icon = Badge(label: Text('${action.badgeCount}'), child: icon);
    }

    return Semantics(
      button: true,
      label: action.tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: action.tooltip,
        child: Material(
          color: fill,
          shape: CircleBorder(side: BorderSide(color: border)),
          child: InkResponse(
            onTap: action.onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox.square(
              dimension: DuoSideBar.buttonSize,
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    );
  }
}
