import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/helpers/settings_store.dart';

void main() {
  late Directory dir;
  late SettingsStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('ajustes');
    store = SettingsStore(directory: () async => dir);
  });

  tearDown(() => dir.delete(recursive: true));

  test('sin archivo devuelve un mapa vacío', () async {
    expect(await store.read(), isEmpty);
  });

  test('lo guardado se lee en la siguiente apertura', () async {
    await store.write({'theme': 'light', 'saveToGallery': false});

    final again = SettingsStore(directory: () async => dir);
    expect(await again.read(), {'theme': 'light', 'saveToGallery': false});
  });

  test('un archivo dañado no rompe la app', () async {
    await File('${dir.path}/ajustes.json').writeAsString('{no es json');

    expect(await store.read(), isEmpty);
  });

  test('un JSON que no es un mapa se ignora', () async {
    await File('${dir.path}/ajustes.json').writeAsString('[1, 2]');

    expect(await store.read(), isEmpty);
  });
}
