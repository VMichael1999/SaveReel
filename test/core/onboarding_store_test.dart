import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/helpers/onboarding_store.dart';

void main() {
  late Directory dir;
  late OnboardingStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('primer_uso');
    store = OnboardingStore(directory: () async => dir);
  });

  tearDown(() => dir.delete(recursive: true));

  test('al principio la guía no se ha descartado', () async {
    expect(await store.isDismissed(), isFalse);
  });

  test('descartarla se recuerda en la siguiente apertura', () async {
    await store.dismiss();

    expect(await store.isDismissed(), isTrue);
    expect(
      await OnboardingStore(directory: () async => dir).isDismissed(),
      isTrue,
    );
  });

  test('descartarla dos veces no falla', () async {
    await store.dismiss();
    await store.dismiss();

    expect(await store.isDismissed(), isTrue);
  });

  test('crea la carpeta si todavía no existe', () async {
    final nested = Directory('${dir.path}/nueva/carpeta');
    final s = OnboardingStore(directory: () async => nested);

    await s.dismiss();

    expect(await s.isDismissed(), isTrue);
  });
}
