import 'package:flutter/widgets.dart';

import 'duo_layout.dart';
import 'duo_side_bar.dart';

/// Ancho de cada mitad en [DuoLayout.openLandscape].
///
/// El centro es el de toda la pantalla, franja incluida: `ancho / 2`. La
/// izquierda llega hasta `centro − 12` y la derecha empieza en `centro + 12`
/// y acaba donde empieza la franja, así que queda más angosta. Nada tocable
/// cruza el centro.
({double left, double right}) duoHalves(double width, double sideBarWidth) {
  final center = width / 2;
  return (
    left: center - kDuoFoldGap,
    right: width - sideBarWidth - (center + kDuoFoldGap),
  );
}

/// Dos mitades separadas en el centro de la pantalla y, a la derecha, la
/// franja lateral.
class DuoSplit extends StatelessWidget {
  const DuoSplit({
    super.key,
    required this.left,
    required this.right,
    required this.sideBar,
  });

  final Widget left;
  final Widget right;
  final Widget sideBar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final halves = duoHalves(
          constraints.maxWidth,
          DuoSideBar.widthFor(context),
        );
        return Row(
          children: [
            SizedBox(
              width: halves.left,
              child: MediaQuery.removePadding(
                context: context,
                removeRight: true,
                child: left,
              ),
            ),
            const SizedBox(width: kDuoFoldGap * 2),
            SizedBox(
              width: halves.right,
              child: MediaQuery.removePadding(
                context: context,
                removeRight: true,
                child: right,
              ),
            ),
            sideBar,
          ],
        );
      },
    );
  }
}
