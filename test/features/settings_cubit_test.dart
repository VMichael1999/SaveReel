import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/settings_cubit/settings_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/models/app_settings.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/models/download_format.dart';

import '../support/fake_library.dart';

void main() {
  group('AppSettings', () {
    test('por omisión es oscuro, con créditos y copia a la galería', () {
      const defaults = AppSettings();

      expect(defaults.theme, AppThemeChoice.dark);
      expect(defaults.theme.themeMode, ThemeMode.dark);
      expect(defaults.defaultFormat, DownloadFormat.withCredits);
      expect(defaults.saveToGallery, isTrue);
    });

    test('ida y vuelta por JSON conserva todo', () {
      const original = AppSettings(
        defaultFormat: DownloadFormat.audio,
        saveToGallery: false,
        theme: AppThemeChoice.system,
      );

      expect(AppSettings.fromJson(original.toJson()), original);
    });

    test('valores desconocidos o ausentes caen en los de omisión', () {
      final parsed = AppSettings.fromJson({
        'defaultFormat': 'inventado',
        'saveToGallery': 'sí',
        'theme': null,
      });

      expect(parsed, const AppSettings());
    });
  });

  group('SettingsCubit', () {
    test('carga lo guardado', () async {
      final store = MemorySettingsStore({'theme': 'light'});
      final cubit = SettingsCubit(store: store);

      await cubit.load();

      expect(cubit.state.theme, AppThemeChoice.light);
      await cubit.close();
    });

    test('cada cambio se aplica al momento y se guarda', () async {
      final store = MemorySettingsStore();
      final cubit = SettingsCubit(store: store);

      await cubit.setSaveToGallery(false);
      await cubit.setDefaultFormat(DownloadFormat.noWatermark);
      await cubit.setTheme(AppThemeChoice.system);

      expect(cubit.state.saveToGallery, isFalse);
      expect(store.saved, {
        'defaultFormat': 'noWatermark',
        'saveToGallery': false,
        'theme': 'system',
      });
      await cubit.close();
    });

    test('un cambio no pisa los demás ajustes', () async {
      final cubit = SettingsCubit(
        store: MemorySettingsStore({'saveToGallery': false}),
      );
      await cubit.load();

      await cubit.setTheme(AppThemeChoice.light);

      expect(cubit.state.saveToGallery, isFalse);
      expect(cubit.state.theme, AppThemeChoice.light);
      await cubit.close();
    });
  });
}
