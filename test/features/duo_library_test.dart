import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/core/layout/duo_side_bar.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/saved_video.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/library_screen.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/widgets/library_screen/library_tile.dart';

import '../support/fake_library.dart';
import '../support/golden.dart';

Future<void> _open(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.view.padding = const FakeViewPadding(right: 84 * 3, bottom: 34 * 3);
  tester.view.viewPadding = const FakeViewPadding(
    right: 84 * 3,
    bottom: 34 * 3,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.path,
      );

  final cubit = fakeLibraryCubit(
    FakeSavedVideosRepo(
      videos: [
        for (var i = 0; i < 9; i++)
          SavedVideo(
            path: '/app/v$i.mp4',
            sizeBytes: 5 * 1048576,
            modified: DateTime(2026, 1, 1).subtract(Duration(days: i)),
            title: 'Video $i',
            durationSeconds: 20 + i,
          ),
      ],
    ),
  );
  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const LibraryScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('en el iPhone normal no hay franja', (tester) async {
    await _open(tester, const Size(393, 852));

    expect(find.byType(DuoSideBar), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('cerrado: las acciones de la barra pasan a la franja', (
    tester,
  ) async {
    await _open(tester, const Size(466, 678));

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(DuoSideBar), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Buscar'), findsOneWidget);
    expect(find.byTooltip('Ordenar'), findsOneWidget);
    expect(find.byTooltip('Seleccionar'), findsOneWidget);
    expect(find.text('Tus descargas'), findsOneWidget);
  });

  testWidgets('cerrado: Seleccionar pone el conteo en el contenido', (
    tester,
  ) async {
    await _open(tester, const Size(466, 678));

    await tester.tap(find.byTooltip('Seleccionar'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('0 seleccionados'), findsOneWidget);
    expect(find.byTooltip('Buscar'), findsNothing);
  });

  testWidgets('cerrado: Ordenar abre las opciones y cambia el orden', (
    tester,
  ) async {
    await _open(tester, const Size(466, 678));

    await tester.tap(find.byTooltip('Ordenar'));
    await tester.pumpAndSettle();
    expect(find.text('Más antiguos'), findsOneWidget);

    await tester.tap(find.text('Más antiguos'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('cerrado: la biblioteca muestra tres columnas', (tester) async {
    await _open(tester, const Size(466, 678));

    final firstRow = tester
        .widgetList<LibraryTile>(find.byType(LibraryTile))
        .where(
          (t) =>
              tester.getTopLeft(find.byWidget(t)).dy ==
              tester.getTopLeft(find.byType(LibraryTile).first).dy,
        );
    expect(firstRow.length, 3);
    await expectGolden(
      find.byType(MaterialApp),
      'goldens/duo/biblioteca_cerrado.png',
    );
  });

  group('otros diseños', () {
    List<Rect> firstRow(WidgetTester tester) {
      final tiles = find.byType(LibraryTile);
      final top = tester.getTopLeft(tiles.first).dy;
      return [
        for (var i = 0; i < tiles.evaluate().length; i++)
          if (tester.getTopLeft(tiles.at(i)).dy == top)
            tester.getRect(tiles.at(i)),
      ];
    }

    testWidgets('abierto en horizontal: 6 columnas y el pliegue entre la 3.ª y '
        'la 4.ª', (tester) async {
      await _open(tester, const Size(951, 669));

      final row = firstRow(tester);
      expect(row.length, 6);
      final gapCenter = (row[2].right + row[3].left) / 2;
      expect(gapCenter, closeTo(951 / 2, 0.01));
      // Simetría: lo que sobra a cada lado del conjunto es la franja.
      expect(row.first.left, closeTo(84, 0.01));
      expect(951 - row.last.right, closeTo(84, 0.01));
    });

    testWidgets('abierto en horizontal: la franja trae las mismas acciones', (
      tester,
    ) async {
      await _open(tester, const Size(951, 669));

      expect(find.byType(DuoSideBar), findsOneWidget);
      expect(find.byTooltip('Buscar'), findsOneWidget);
      expect(find.byTooltip('Seleccionar'), findsOneWidget);
    });

    testWidgets('abierto en vertical: 4 columnas, con barra arriba como hoy', (
      tester,
    ) async {
      await _open(tester, const Size(669, 951));

      expect(firstRow(tester).length, 4);
      expect(find.byType(DuoSideBar), findsNothing);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
