import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/routes_manager.dart';

void main() {
  test('un enlace como ruta inicial arma una sola pantalla, no varias', () {
    final routes = AppRouter.initialRoutes(
      'savetic://share?text=https://www.tiktok.com/@a/video/1',
    );
    expect(routes, hasLength(1));
  });

  test('la ruta inicial normal también es una sola', () {
    expect(AppRouter.initialRoutes(Routes.splash), hasLength(1));
  });
}
