import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/routes_manager.dart';

void main() {
  test(
    'una ruta desconocida no devuelve nulo: vuelve a la pantalla inicial',
    () {
      // Android puede entregar la dirección de un enlace externo (`/clipboard`)
      // como ruta; sin salida, el arranque se rompía.
      for (final name in ['/clipboard', '/share', '/algo/raro', '']) {
        final route = AppRouter.getRoute(RouteSettings(name: name));
        expect(route, isA<MaterialPageRoute<dynamic>>(), reason: name);
      }
    },
  );

  test('las rutas conocidas siguen siendo las suyas', () {
    final route = AppRouter.getRoute(const RouteSettings(name: Routes.library));
    expect(route, isA<MaterialPageRoute<dynamic>>());
  });
}
