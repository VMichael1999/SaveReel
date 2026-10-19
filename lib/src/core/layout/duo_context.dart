import 'package:flutter/widgets.dart';

import 'duo_layout.dart';

/// El diseño que corresponde a la pantalla donde está este contexto.
extension DuoLayoutContext on BuildContext {
  DuoLayout get duoLayout => duoLayoutFor(MediaQuery.sizeOf(this));

  /// Si hay franja lateral (pantalla exterior o interior abierta en horizontal).
  bool get hasDuoSideBar {
    final layout = duoLayout;
    return layout == DuoLayout.closed || layout == DuoLayout.openLandscape;
  }
}
