import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/saved_video.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/settings_cubit/settings_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/models/app_settings.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/models/download_format.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/settings_screen.dart';

import '../support/fake_library.dart';

class _Opened {
  _Opened(this.settings, this.repo);

  final SettingsCubit settings;
  final FakeSavedVideosRepo repo;
}

Future<_Opened> _open(
  WidgetTester tester, {
  AppSettings initial = const AppSettings(),
  int cacheBytes = 3355443, // 3.2 MB
}) async {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final repo = FakeSavedVideosRepo(
    videos: [
      for (var i = 0; i < 3; i++)
        SavedVideo(
          path: '/app/$i.mp4',
          sizeBytes: 5 * 1048576,
          modified: DateTime(2026, 1, 1),
          durationSeconds: 10,
        ),
    ],
  )..cacheBytes = cacheBytes;
  final library = fakeLibraryCubit(repo);
  await library.load();
  final settings = fakeSettingsCubit(initial);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<LibraryCubit>.value(value: library),
        BlocProvider<SettingsCubit>.value(value: settings),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const SettingsScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return _Opened(settings, repo);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('muestra los tres controles con sus valores de fábrica', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Formato'), findsOneWidget);
    expect(find.text('Con créditos'), findsOneWidget);
    expect(find.text('Guardar en la Galería'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Oscuro'), findsOneWidget);
  });

  testWidgets('el espacio muestra cuántos archivos hay y cuánto pesan', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('3 archivos'), findsOneWidget);
    expect(find.text('15.0 MB'), findsOneWidget);
    expect(find.text('3.2 MB'), findsOneWidget);
  });

  testWidgets('el aviso de que no está afiliada a TikTok ni a Instagram está a la vista', (
    tester,
  ) async {
    await _open(tester);

    expect(find.textContaining('no está afiliada a TikTok ni a Instagram'), findsOneWidget);
  });

  testWidgets('apagar «Guardar en la Galería» se aplica y se guarda', (
    tester,
  ) async {
    final opened = await _open(tester);

    await tester.tap(find.byType(SwitchListTile));
    await _settle(tester);

    expect(opened.settings.state.saveToGallery, isFalse);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
  });

  testWidgets('elegir el formato predeterminado cambia su valor', (
    tester,
  ) async {
    final opened = await _open(tester);

    await tester.tap(find.text('Formato'));
    await _settle(tester);
    expect(find.text('Video sin marca de agua'), findsOneWidget);

    await tester.tap(find.text('Solo el audio'));
    await _settle(tester);

    expect(opened.settings.state.defaultFormat, DownloadFormat.audio);
    expect(find.text('Solo audio'), findsOneWidget);
  });

  testWidgets('los datos móviles preguntan si pesa mucho por omisión', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Datos móviles'), findsOneWidget);
    expect(find.text('Preguntar'), findsOneWidget);
  });

  testWidgets('elegir «Solo con Wi-Fi» cambia la política y se muestra', (
    tester,
  ) async {
    final opened = await _open(tester);

    await tester.tap(find.text('Datos móviles'));
    await _settle(tester);
    expect(
      find.text('Con datos móviles te pregunta antes de cada descarga'),
      findsOneWidget,
    );

    await tester.tap(find.text('Solo con Wi-Fi'));
    await _settle(tester);

    expect(opened.settings.state.mobileData, MobileDataPolicy.wifiOnly);
    expect(find.text('Solo Wi-Fi'), findsOneWidget);
  });

  testWidgets('elegir el tema lo cambia y la hoja se cierra', (tester) async {
    final opened = await _open(tester);

    await tester.tap(find.text('Tema'));
    await _settle(tester);
    expect(find.text('Sigue el tema de tu teléfono'), findsOneWidget);

    await tester.tap(find.text('Claro'));
    await _settle(tester);

    expect(opened.settings.state.theme, AppThemeChoice.light);
    expect(find.text('Sigue el tema de tu teléfono'), findsNothing);
  });

  testWidgets('borrar las miniaturas en caché lo avisa y deja el caché vacío', (
    tester,
  ) async {
    final opened = await _open(tester);

    await tester.tap(find.text('Borrar miniaturas en caché'));
    await _settle(tester);

    expect(opened.repo.cacheClears, 1);
    // El aviso se dibuja un par de cuadros después de pedirlo.
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Miniaturas borradas'), findsOneWidget);
    expect(find.text('0 MB'), findsOneWidget);
    await drainToasts(tester);
  });

  testWidgets('con el caché vacío no ofrece borrarlo', (tester) async {
    final opened = await _open(tester, cacheBytes: 0);

    await tester.tap(find.text('Borrar miniaturas en caché'));
    await _settle(tester);

    expect(opened.repo.cacheClears, 0);
  });

  testWidgets('lo elegido se recuerda al abrir de nuevo', (tester) async {
    final store = MemorySettingsStore();
    final cubit = SettingsCubit(store: store);
    await cubit.setTheme(AppThemeChoice.system);

    final reopened = SettingsCubit(store: store);
    await reopened.load();

    expect(reopened.state.theme, AppThemeChoice.system);
  });
}
