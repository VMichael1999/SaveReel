import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/saved_video.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/library_screen.dart';

import '../support/fake_library.dart';

SavedVideo _video(String name, {int? seconds, String? title}) => SavedVideo(
  path: '/app/$name',
  sizeBytes: 5 * 1048576,
  modified: DateTime(2026, 1, 1),
  title: title,
  durationSeconds: seconds,
);

Future<LibraryCubit> _open(WidgetTester tester, List<SavedVideo> videos) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final cubit = fakeLibraryCubit(FakeSavedVideosRepo(videos: videos));
  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: MaterialApp(theme: AppTheme.dark, home: const LibraryScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return cubit;
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });

  testWidgets(
    'muestra el total de archivos, el peso y los filtros con cantidad',
    (tester) async {
      await _open(tester, [
        _video('a.mp4', seconds: 34),
        _video('b.mp4', seconds: 72),
        _video('c.mp3', seconds: 59),
      ]);

      expect(find.text('Tus descargas'), findsOneWidget);
      expect(find.text('3 archivos · 15.0 MB'), findsOneWidget);
      expect(find.textContaining('Todo 3'), findsOneWidget);
      expect(find.textContaining('Videos 2'), findsOneWidget);
      expect(find.textContaining('Audio 1'), findsOneWidget);
    },
  );

  testWidgets('cada miniatura lleva su duración y el audio se distingue', (
    tester,
  ) async {
    await _open(tester, [
      _video('a.mp4', seconds: 34),
      _video('b.mp4', seconds: 72),
      _video('c.mp3', seconds: 59),
    ]);

    expect(find.text('0:34'), findsOneWidget);
    expect(find.text('1:12'), findsOneWidget);
    expect(find.text('0:59'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Reproducir video guardado, audio, 0:59'),
      findsOneWidget,
    );
  });

  testWidgets('el filtro Audio deja solo los audios', (tester) async {
    await _open(tester, [
      _video('a.mp4', seconds: 34),
      _video('c.mp3', seconds: 59),
    ]);

    await tester.tap(find.textContaining('Audio 1'));
    await tester.pump();

    expect(find.text('0:34'), findsNothing);
    expect(find.text('0:59'), findsOneWidget);
  });

  testWidgets('un filtro sin resultados lo dice', (tester) async {
    await _open(tester, [_video('a.mp4', seconds: 34)]);

    await tester.tap(find.textContaining('Audio 0'));
    await tester.pump();

    expect(find.text('No hay nada en este filtro.'), findsOneWidget);
  });

  testWidgets('sin videos guardados muestra el estado vacío', (tester) async {
    await _open(tester, []);

    expect(find.text('Aún no has guardado nada'), findsOneWidget);
    expect(find.text('Tus descargas'), findsNothing);
  });

  testWidgets('la miniatura se describe con el título cuando se conoce', (
    tester,
  ) async {
    await _open(tester, [
      _video('a.mp4', seconds: 34, title: 'Lomo saltado'),
      _video('b.mp4', seconds: 10),
    ]);

    expect(
      find.bySemanticsLabel('Reproducir Lomo saltado, 0:34'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Reproducir video guardado, 0:10'),
      findsOneWidget,
    );
  });
}
