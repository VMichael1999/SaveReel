import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Los goldens se generan en macOS: el texto se dibuja con otros píxeles en
/// Linux, así que ahí darían falsos fallos. Se comparan solo en macOS; el
/// resto de cada prueba corre en todas partes.
Future<void> expectGolden(Finder finder, String path) async {
  if (!Platform.isMacOS) return;
  await expectLater(finder, matchesGoldenFile(path));
}
