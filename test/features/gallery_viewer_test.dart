import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/core/error/failure.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/cancel_signal.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/tiktok_video.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/repositories/tiktok_video_base_repo.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_file_size_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/save_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/downloader_bloc/downloader_bloc.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/models/video_player_args.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/gallery_viewer_screen.dart';

import '../support/fake_library.dart';

class _NoRepo implements TiktokVideoBaseRepo {
  @override
  Future<Either<Failure, TikTokVideo>> getVideo(String videoLink) async =>
      const Left(NotFoundFailure());

  @override
  Future<Either<Failure, int?>> getFileSize(String url) async =>
      const Right(null);

  @override
  Future<Either<Failure, String>> saveVideo({
    required String videoLink,
    required String savePath,
    void Function(int received, int total)? onProgress,
    CancelSignal? cancelSignal,
  }) async => const Right('ok');
}

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  late Directory dir;
  late DownloaderBloc bloc;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('visor');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => dir.path,
        );
    final repo = _NoRepo();
    bloc = DownloaderBloc(
      getVideoUseCase: GetVideoUseCase(videoRepo: repo),
      saveVideoUseCase: SaveVideoUseCase(videoRepo: repo),
      getFileSizeUseCase: GetFileSizeUseCase(videoRepo: repo),
    );
  });

  tearDown(() {
    // Borrar la galería ya quitó la carpeta.
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<List<String>> pumpViewer(
    WidgetTester tester, {
    Future<void> Function(String path)? saver,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final files = <String>[];
    for (final name in ['01.jpg', '02.jpg', '03.jpg']) {
      final file = File('${dir.path}/$name')..writeAsBytesSync(_png);
      files.add(file.path);
    }
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: TextButton(
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => GalleryViewerScreen(
                                  saveToGallery: saver ?? (_) async {},
                                  args: VideoPlayerArgs(
                                    path: dir.path,
                                    title: 'Viaje a Cusco',
                                    authorHandle: 'viajes.peru',
                                    files: files,
                                  ),
                                ),
                          ),
                        ),
                    child: const Text('abrir'),
                  ),
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return files;
  }

  testWidgets('muestra la posición, el título y las acciones', (tester) async {
    await pumpViewer(tester);

    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Viaje a Cusco'), findsOneWidget);
    expect(find.text('@viajes.peru'), findsOneWidget);
    expect(find.text('Compartir'), findsOneWidget);
    expect(find.text('Guardar en galería'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets('deslizar cambia de pieza y actualiza la posición', (
    tester,
  ) async {
    await pumpViewer(tester);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('con la foto ampliada el arrastre no cambia de página', (
    tester,
  ) async {
    await pumpViewer(tester);

    await tester.tap(find.byType(PageView));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(PageView));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);

    // Otro doble toque la devuelve a su tamaño y vuelve a poder deslizar.
    await tester.tap(find.byType(PageView));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(PageView));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('un pellizco amplía la foto', (tester) async {
    await pumpViewer(tester);
    final center = tester.getCenter(find.byType(PageView));

    final a = await tester.startGesture(center - const Offset(40, 0));
    final b = await tester.startGesture(center + const Offset(40, 0));
    await a.moveBy(const Offset(-80, 0));
    await b.moveBy(const Offset(80, 0));
    await a.up();
    await b.up();
    await tester.pump();

    // Ampliada, el arrastre ya no cambia de página.
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('eliminar pide confirmar y cancelar no borra nada', (
    tester,
  ) async {
    await pumpViewer(tester);
    final events = <Object>[];
    final sub = bloc.stream.listen(events.add);
    addTearDown(sub.cancel);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar este video?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 3'), findsOneWidget);
    expect(events, isEmpty);
  });

  testWidgets('confirmar borra la galería y vuelve atrás', (tester) async {
    await pumpViewer(tester);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.text('1 / 3'), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  });

  Future<void> showUp(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('guarda cada pieza en la galería, lo marca y avisa', (
    tester,
  ) async {
    final saved = <String>[];
    final files = await pumpViewer(
      tester,
      saver: (path) async => saved.add(path),
    );

    await tester.tap(find.text('Guardar en galería'));
    await showUp(tester);

    expect(saved, files);
    expect(find.text('Guardado en tu galería'), findsOneWidget);
    expect(find.text('En galería'), findsOneWidget);
    expect(find.text('Guardar en galería'), findsNothing);
    await drainToasts(tester);
  });

  testWidgets('si la galería falla lo avisa y deja volver a intentar', (
    tester,
  ) async {
    await pumpViewer(tester, saver: (_) async => throw Exception('permiso'));

    await tester.tap(find.text('Guardar en galería'));
    await showUp(tester);

    expect(
      find.textContaining('No pudimos guardarlo en la galería'),
      findsOneWidget,
    );
    expect(find.text('Guardar en galería'), findsOneWidget);
    await drainToasts(tester);
  });
}
