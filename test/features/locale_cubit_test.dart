import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/locale_cubit/locale_cubit.dart';
import 'package:savetic/src/localization/app_texts.dart';

import '../support/fake_library.dart';

LocaleCubit _cubit(MemoryLanguageStore store, {String device = 'es'}) =>
    LocaleCubit(store: store, deviceLocale: () => Locale(device));

void main() {
  tearDown(() => AppTexts.active = AppLanguages.fallback);

  test(
    'sin idioma guardado sigue el del teléfono si la app lo tiene',
    () async {
      final cubit = _cubit(MemoryLanguageStore(), device: 'en');
      await cubit.load();
      expect(cubit.state, const Locale('en'));
      expect(AppTexts.active, 'en');
    },
  );

  test(
    'si el teléfono usa uno que la app no tiene, queda el de respaldo',
    () async {
      final cubit = _cubit(MemoryLanguageStore(), device: 'ja');
      await cubit.load();
      expect(cubit.state, const Locale(AppLanguages.fallback));
    },
  );

  test('lo guardado gana sobre el idioma del teléfono', () async {
    final cubit = _cubit(MemoryLanguageStore('es'), device: 'en');
    await cubit.load();
    expect(cubit.state, const Locale('es'));
  });

  test('setLanguage cambia, avisa a los textos y guarda', () async {
    final store = MemoryLanguageStore();
    final cubit = _cubit(store);
    await cubit.load();
    await cubit.setLanguage('en');
    expect(cubit.state, const Locale('en'));
    expect(AppTexts.active, 'en');
    expect(store.saved, 'en');
  });

  test('un código que la app no tiene se ignora', () async {
    final store = MemoryLanguageStore();
    final cubit = _cubit(store);
    await cubit.load();
    await cubit.setLanguage('xx');
    expect(cubit.state, const Locale('es'));
    expect(store.saved, isNull);
  });

  test('un código guardado que ya no existe se ignora al cargar', () async {
    final cubit = _cubit(MemoryLanguageStore('xx'));
    await cubit.load();
    expect(cubit.state, const Locale('es'));
  });
}
