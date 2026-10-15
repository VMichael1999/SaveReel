import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/core/error/failure.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/cancel_signal.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/saved_video.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/tiktok_video.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/repositories/tiktok_video_base_repo.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_file_size_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/save_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/downloader_bloc/downloader_bloc.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/library_screen.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/widgets/library_screen/library_tile.dart';

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

SavedVideo _v(
  String name, {
  String? title,
  String? author,
  int mb = 1,
  int day = 1,
}) => SavedVideo(
  path: '/app/$name',
  sizeBytes: mb * 1048576,
  modified: DateTime(2026, 1, day),
  title: title,
  authorHandle: author,
  durationSeconds: 10,
);

final _library = [
  _v('a.mp4', title: 'Lomo saltado', author: 'cocinaconlucia', mb: 8, day: 3),
  _v('b.mp4', title: 'Ceviche clásico', author: 'rutas.lima', mb: 2, day: 2),
  _v('c.mp3', title: 'Canción de cuna', author: 'musica.pe', mb: 4, day: 1),
];

late DownloaderBloc _bloc;

Future<void> _open(WidgetTester tester, [List<SavedVideo>? videos]) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.path,
      );
  final repo = _NoRepo();
  _bloc = DownloaderBloc(
    getVideoUseCase: GetVideoUseCase(videoRepo: repo),
    saveVideoUseCase: SaveVideoUseCase(videoRepo: repo),
    getFileSizeUseCase: GetFileSizeUseCase(videoRepo: repo),
  );
  final cubit = fakeLibraryCubit(
    FakeSavedVideosRepo(videos: videos ?? _library),
  );
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<LibraryCubit>.value(value: cubit),
        BlocProvider<DownloaderBloc>.value(value: _bloc),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const LibraryScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

List<String?> _titles(WidgetTester tester) => [
  for (final tile in tester.widgetList<LibraryTile>(find.byType(LibraryTile)))
    tile.video.title,
];

Future<void> _type(WidgetTester tester, String text) async {
  await tester.tap(find.byTooltip('Buscar'));
  await tester.pump();
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

void main() {
  group('búsqueda', () {
    testWidgets('filtra por título mientras se escribe', (tester) async {
      await _open(tester);
      expect(_titles(tester), hasLength(3));

      await _type(tester, 'lomo');

      expect(_titles(tester), ['Lomo saltado']);
    });

    testWidgets('no distingue tildes ni mayúsculas', (tester) async {
      await _open(tester);

      await _type(tester, 'CANCION');

      expect(_titles(tester), ['Canción de cuna']);
    });

    testWidgets('también busca por autor', (tester) async {
      await _open(tester);

      await _type(tester, 'rutas lima');

      expect(_titles(tester), ['Ceviche clásico']);
    });

    testWidgets('sin coincidencias lo dice con lo escrito', (tester) async {
      await _open(tester);

      await _type(tester, 'pizza');

      expect(_titles(tester), isEmpty);
      expect(find.text('Nada coincide con «pizza».'), findsOneWidget);
    });

    testWidgets('borrar lo escrito y cerrar la búsqueda devuelven todo', (
      tester,
    ) async {
      await _open(tester);
      await _type(tester, 'lomo');

      await tester.tap(find.byTooltip('Borrar lo escrito'));
      await tester.pump();
      expect(_titles(tester), hasLength(3));

      await tester.enterText(find.byType(TextField), 'lomo');
      await tester.pump();
      await tester.tap(find.byTooltip('Cerrar la búsqueda'));
      await tester.pump();

      expect(find.byType(TextField), findsNothing);
      expect(_titles(tester), hasLength(3));
    });

    testWidgets('se combina con los filtros', (tester) async {
      await _open(tester);
      await _type(tester, 'c');
      expect(_titles(tester), hasLength(3)); // «c» está en los tres

      await tester.tap(find.textContaining('Audio 1'));
      await tester.pump();

      expect(_titles(tester), ['Canción de cuna']);
    });
  });

  group('orden', () {
    testWidgets('por omisión, del más nuevo al más antiguo', (tester) async {
      await _open(tester);
      expect(_titles(tester), [
        'Lomo saltado',
        'Ceviche clásico',
        'Canción de cuna',
      ]);
    });

    testWidgets('el menú cambia el orden', (tester) async {
      await _open(tester);

      await tester.tap(find.byTooltip('Ordenar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Más pesados'));
      await tester.pumpAndSettle();
      expect(_titles(tester), [
        'Lomo saltado',
        'Canción de cuna',
        'Ceviche clásico',
      ]);

      await tester.tap(find.byTooltip('Ordenar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Título (A–Z)'));
      await tester.pumpAndSettle();
      expect(_titles(tester), [
        'Canción de cuna',
        'Ceviche clásico',
        'Lomo saltado',
      ]);
    });
  });

  group('selección múltiple', () {
    Future<void> startSelecting(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Seleccionar'));
      await tester.pump();
    }

    testWidgets('tocar marca y desmarca, y cuenta lo elegido', (tester) async {
      await _open(tester);
      await startSelecting(tester);
      expect(find.text('0 seleccionados'), findsOneWidget);

      await tester.tap(find.byType(LibraryTile).first);
      await tester.pump();
      expect(find.text('1 seleccionado'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.byType(LibraryTile).at(1));
      await tester.pump();
      expect(find.text('2 seleccionados'), findsOneWidget);

      await tester.tap(find.byType(LibraryTile).first);
      await tester.pump();
      expect(find.text('1 seleccionado'), findsOneWidget);
    });

    testWidgets('sin nada elegido las acciones están apagadas', (tester) async {
      await _open(tester);
      await startSelecting(tester);

      final delete = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Eliminar'),
          matching: find.byType(InkWell),
        ),
      );
      expect(delete.onTap, isNull);
      expect(find.text('Compartir'), findsOneWidget);
      expect(find.text('Galería'), findsOneWidget);
    });

    testWidgets('seleccionar todo elige los que se ven', (tester) async {
      await _open(tester);
      await startSelecting(tester);

      await tester.tap(find.byTooltip('Seleccionar todo'));
      await tester.pump();

      expect(find.text('3 seleccionados'), findsOneWidget);
    });

    testWidgets('empezar a seleccionar cierra la búsqueda', (tester) async {
      await _open(tester);
      await _type(tester, 'lomo');
      expect(find.byType(TextField), findsOneWidget);

      // Con la búsqueda abierta no está el botón de seleccionar: se cierra
      // primero, y entonces vuelve a verse toda la biblioteca.
      await tester.tap(find.byTooltip('Cerrar la búsqueda'));
      await tester.pump();
      await startSelecting(tester);

      expect(find.byType(TextField), findsNothing);
      expect(find.text('0 seleccionados'), findsOneWidget);
      expect(_titles(tester), hasLength(3));
    });

    testWidgets('cancelar la selección vuelve a la vista normal', (
      tester,
    ) async {
      await _open(tester);
      await startSelecting(tester);
      await tester.tap(find.byType(LibraryTile).first);
      await tester.pump();

      await tester.tap(find.byTooltip('Cancelar la selección'));
      await tester.pump();

      expect(find.textContaining('seleccionad'), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byTooltip('Buscar'), findsOneWidget);
    });

    testWidgets('el botón atrás sale de la selección sin cerrar la pantalla', (
      tester,
    ) async {
      await _open(tester);
      await startSelecting(tester);

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.textContaining('seleccionad'), findsNothing);
      expect(find.byType(LibraryTile), findsNWidgets(3));
    });

    testWidgets('mantener pulsado ofrece Seleccionar y empieza con ese', (
      tester,
    ) async {
      await _open(tester);

      await tester.longPress(find.byType(LibraryTile).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seleccionar'));
      await tester.pumpAndSettle();

      expect(find.text('1 seleccionado'), findsOneWidget);
    });

    testWidgets('eliminar pide confirmar y cancelar no borra nada', (
      tester,
    ) async {
      await _open(tester);
      await startSelecting(tester);
      await tester.tap(find.byType(LibraryTile).first);
      await tester.tap(find.byType(LibraryTile).at(1));
      await tester.pump();
      final events = <Object>[];
      final sub = _bloc.stream.listen(events.add);
      addTearDown(sub.cancel);

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar 2 elementos?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('2 seleccionados'), findsOneWidget);
      expect(events, isEmpty);
    });

    testWidgets('confirmar borra los elegidos y sale de la selección', (
      tester,
    ) async {
      await _open(tester);
      await startSelecting(tester);
      await tester.tap(find.byType(LibraryTile).first);
      await tester.tap(find.byType(LibraryTile).at(1));
      await tester.pump();
      final deleted = <String>[];
      final sub = _bloc.stream.listen((s) {
        if (s is DownloaderVideoDeleted) deleted.add(s.path);
      });
      addTearDown(sub.cancel);

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
      await tester.pump();
      // Borrar usa disco real: se espera a que lleguen los dos avisos.
      for (var i = 0; i < 200 && deleted.length < 2; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }

      expect(deleted.toSet(), {'/app/a.mp4', '/app/b.mp4'});
      expect(find.textContaining('seleccionad'), findsNothing);
    });
  });
}
