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
        mobileData: MobileDataPolicy.wifiOnly,
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

    test('con datos móviles pregunta solo si pesa mucho, por omisión', () {
      expect(const AppSettings().mobileData, MobileDataPolicy.ask);
    });
  });

  group('MobileDataPolicy.needsConfirmation', () {
    const heavy = MobileDataPolicy.heavyBytes;

    test('«descargar siempre» nunca pregunta', () {
      for (final metered in [true, false]) {
        expect(
          MobileDataPolicy.allow.needsConfirmation(
            metered: metered,
            bytes: heavy * 10,
          ),
          isFalse,
        );
      }
    });

    test('«solo con Wi-Fi» pregunta siempre que la red sea de pago', () {
      const policy = MobileDataPolicy.wifiOnly;
      expect(policy.needsConfirmation(metered: true, bytes: 1), isTrue);
      expect(policy.needsConfirmation(metered: true, bytes: null), isTrue);
      expect(policy.needsConfirmation(metered: false, bytes: heavy), isFalse);
    });

    test('«preguntar» solo si es de pago y pesa 50 MB o más', () {
      const policy = MobileDataPolicy.ask;
      expect(policy.needsConfirmation(metered: true, bytes: heavy), isTrue);
      expect(
        policy.needsConfirmation(metered: true, bytes: heavy - 1),
        isFalse,
      );
      expect(
        policy.needsConfirmation(metered: false, bytes: heavy * 3),
        isFalse,
      );
      // Sin saber el peso no se interrumpe al usuario.
      expect(policy.needsConfirmation(metered: true, bytes: null), isFalse);
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
        'mobileData': 'ask',
      });
      await cubit.close();
    });

    test(
      'cambiar la política de datos móviles se aplica y se guarda',
      () async {
        final store = MemorySettingsStore();
        final cubit = SettingsCubit(store: store);
        await cubit.load();

        await cubit.setMobileData(MobileDataPolicy.wifiOnly);

        expect(cubit.state.mobileData, MobileDataPolicy.wifiOnly);
        expect(store.saved['mobileData'], 'wifiOnly');
        await cubit.close();
      },
    );

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
