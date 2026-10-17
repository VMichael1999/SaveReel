import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/saved_video.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/library_screen.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/widgets/library_screen/library_actions_sheet.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/widgets/library_screen/library_tile.dart';

import '../support/fake_library.dart';

SavedVideo _video(String name, {String? title, String? author}) => SavedVideo(
  path: '/app/$name',
  sizeBytes: 1048576,
  modified: DateTime(2026, 1, 1),
  title: title,
  authorHandle: author,
  durationSeconds: 30,
);

void _mockPlatform() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.path,
      );
}

Future<void> _openLibrary(WidgetTester tester, List<SavedVideo> videos) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  _mockPlatform();
  final cubit = fakeLibraryCubit(FakeSavedVideosRepo(videos: videos));
  await tester.pumpWidget(
    BlocProvider<LibraryCubit>.value(
      value: cubit,
      child: MaterialApp(theme: AppTheme.dark, home: const LibraryScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('mantener pulsada una miniatura abre las acciones del video', (
    tester,
  ) async {
    await _openLibrary(tester, [
      _video('a.mp4', title: 'Lomo saltado', author: 'cocinaconlucia'),
    ]);

    await tester.longPress(find.byType(LibraryTile));
    await tester.pumpAndSettle();

    expect(find.text('Lomo saltado'), findsOneWidget);
    expect(find.text('@cocinaconlucia'), findsOneWidget);
    expect(find.text('Compartir'), findsOneWidget);
    expect(find.text('Guardar en galería'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets('un audio no ofrece guardar en la galería', (tester) async {
    await _openLibrary(tester, [_video('a.mp3', title: 'Canción')]);

    await tester.longPress(find.byType(LibraryTile));
    await tester.pumpAndSettle();

    expect(find.text('Compartir'), findsOneWidget);
    expect(find.text('Guardar en galería'), findsNothing);
    expect(find.text('Eliminar'), findsOneWidget);
  });

  Future<List<String>> pumpSheetHost(
    WidgetTester tester, {
    required Future<void> Function(String path) saver,
  }) async {
    final saved = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed:
                      () => showLibraryActionsSheet(
                        context,
                        _video('a.mp4', title: 'Mi video'),
                        saveToGallery: (path) async {
                          saved.add(path);
                          await saver(path);
                        },
                      ),
                  child: const Text('abrir'),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return saved;
  }

  testWidgets('guardar en la galería lo hace y avisa', (tester) async {
    final saved = await pumpSheetHost(tester, saver: (_) async {});

    await tester.tap(find.text('Guardar en galería'));
    await tester.pumpAndSettle();

    expect(saved, ['/app/a.mp4']);
    expect(find.text('Guardado en tu galería'), findsOneWidget);
    await drainToasts(tester);
  });

  testWidgets('si la galería falla lo dice', (tester) async {
    await pumpSheetHost(tester, saver: (_) async => throw Exception('permiso'));

    await tester.tap(find.text('Guardar en galería'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No pudimos guardarlo en la galería'),
      findsOneWidget,
    );
    await drainToasts(tester);
  });

  testWidgets('«Agregar a favoritos» marca el video y muestra el corazón', (
    tester,
  ) async {
    await _openLibrary(tester, [_video('a.mp4', title: 'Lomo saltado')]);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);

    await tester.longPress(find.byType(LibraryTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar a favoritos'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

    await tester.longPress(find.byType(LibraryTile));
    await tester.pumpAndSettle();
    expect(find.text('Quitar de favoritos'), findsOneWidget);
    await tester.tap(find.text('Quitar de favoritos'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
  });

  testWidgets('el filtro Favoritos solo aparece con favoritos y los filtra', (
    tester,
  ) async {
    await _openLibrary(tester, [
      _video('a.mp4', title: 'Lomo saltado'),
      _video('b.mp4', title: 'Ceviche'),
    ]);
    expect(find.text('Favoritos'), findsNothing);

    await tester.longPress(find.byType(LibraryTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar a favoritos'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Favoritos'));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryTile), findsOneWidget);
  });
}
