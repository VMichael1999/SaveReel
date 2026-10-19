import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/core/layout/duo_side_bar.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/locale_cubit/locale_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/settings_cubit/settings_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/models/app_settings.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/settings_screen.dart';

import '../support/fake_library.dart';

const _open = Size(951, 669);
const _closed = Size(466, 678);

Future<SettingsCubit> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final library = fakeLibraryCubit(FakeSavedVideosRepo());
  await library.load();
  final settings = fakeSettingsCubit();
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<LibraryCubit>.value(value: library),
        BlocProvider<SettingsCubit>.value(value: settings),
        BlocProvider<LocaleCubit>.value(value: fakeLocaleCubit()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return settings;
}

void main() {
  testWidgets('abierto: la lista queda a la izquierda y Volver en la franja', (
    tester,
  ) async {
    await _pump(tester, _open);

    expect(find.byType(DuoSideBar), findsOneWidget);
    expect(find.byTooltip('Volver'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Ajustes'), findsOneWidget);
    expect(
      tester.getTopRight(find.text('Datos móviles')).dx,
      lessThan(951 / 2),
    );
  });

  testWidgets('abierto: la opción se elige a la derecha, sin hoja', (
    tester,
  ) async {
    final settings = await _pump(tester, _open);

    await tester.tap(find.text('Datos móviles'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Preguntar si pesa mucho'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Preguntar si pesa mucho')).dx,
      greaterThan(951 / 2),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/duo/ajustes_abierto.png'),
    );

    await tester.tap(find.text('Solo con Wi-Fi'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(settings.state.mobileData, MobileDataPolicy.wifiOnly);
    // La derecha sigue mostrando las opciones, ya con la nueva elegida.
    expect(find.text('Preguntar si pesa mucho'), findsOneWidget);
  });

  testWidgets('cerrado: la misma opción es una hoja', (tester) async {
    await _pump(tester, _closed);

    await tester.tap(find.text('Datos móviles'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Preguntar si pesa mucho'), findsOneWidget);
  });

  testWidgets('al cerrar el teléfono la opción vuelve a ser la hoja', (
    tester,
  ) async {
    await _pump(tester, _open);
    await tester.tap(find.text('Datos móviles'));
    await tester.pump(const Duration(milliseconds: 300));

    tester.view.physicalSize = _closed * 3;
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Preguntar si pesa mucho'), findsOneWidget);
  });

  testWidgets('al abrir el teléfono con la hoja abierta pasa a la derecha', (
    tester,
  ) async {
    await _pump(tester, _closed);
    await tester.tap(find.text('Datos móviles'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);

    tester.view.physicalSize = _open * 3;
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Preguntar si pesa mucho'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Preguntar si pesa mucho')).dx,
      greaterThan(951 / 2),
    );
  });

  testWidgets('en un iPhone normal no hay franja', (tester) async {
    await _pump(tester, const Size(393, 852));

    expect(find.byType(DuoSideBar), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
