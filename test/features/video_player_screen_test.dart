import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
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
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/video_player_screen.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Reproductor falso: registra las llamadas y simula un video de 34 s.
class _FakePlayer extends VideoPlayerPlatform with MockPlatformInterfaceMixin {
  _FakePlayer({this.failOnCreate = false});

  final bool failOnCreate;
  final List<String> calls = [];
  final _events = StreamController<VideoEvent>();

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async {
    if (failOnCreate) throw PlatformException(code: 'sin_archivo');
    _events.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 34),
        size: const Size(1080, 1920),
      ),
    );
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events.stream;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> play(int playerId) async => calls.add('play');

  @override
  Future<void> pause(int playerId) async => calls.add('pause');

  @override
  Future<void> seekTo(int playerId, Duration position) async =>
      calls.add('seek:${position.inSeconds}');

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Widget buildView(int playerId) => const SizedBox.expand();
}

class _Repo implements TiktokVideoBaseRepo {
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

Future<_FakePlayer> _open(
  WidgetTester tester,
  VideoPlayerArgs args, {
  bool failOnCreate = false,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final player = _FakePlayer(failOnCreate: failOnCreate);
  VideoPlayerPlatform.instance = player;

  final repo = _Repo();
  final bloc = DownloaderBloc(
    getVideoUseCase: GetVideoUseCase(videoRepo: repo),
    saveVideoUseCase: SaveVideoUseCase(videoRepo: repo),
    getFileSizeUseCase: GetFileSizeUseCase(videoRepo: repo),
  );

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
                          builder: (_) => VideoPlayerScreen(args: args),
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
  return player;
}

const _args = VideoPlayerArgs(
  path: 'video.mp4',
  title: 'Lomo saltado en 10 minutos, versión fácil',
  authorHandle: 'cocinaconlucia',
);

void main() {
  testWidgets('muestra el título, el autor, los tiempos y las tres acciones', (
    tester,
  ) async {
    await _open(tester, _args);

    expect(
      find.text('Lomo saltado en 10 minutos, versión fácil'),
      findsOneWidget,
    );
    expect(find.text('@cocinaconlucia'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('0:34'), findsOneWidget);
    expect(find.text('Compartir'), findsOneWidget);
    expect(find.text('Guardar en galería'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
    expect(find.byTooltip('Volver'), findsOneWidget);
  });

  testWidgets('tocar el video lo pausa y vuelve a reproducirlo', (
    tester,
  ) async {
    final player = await _open(tester, _args);
    expect(player.calls, contains('play'));

    await tester.tapAt(const Offset(180, 300));
    await tester.pump();
    expect(player.calls.last, 'pause');
  });

  testWidgets('un audio no ofrece guardar en la galería', (tester) async {
    await _open(tester, const VideoPlayerArgs(path: 'sonido.mp3'));

    expect(find.text('Guardar en galería'), findsNothing);
    expect(find.text('Compartir'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets(
    'si ya está en la galería lo dice y no ofrece guardarlo otra vez',
    (tester) async {
      await _open(
        tester,
        const VideoPlayerArgs(path: 'video.mp4', inGallery: true),
      );

      expect(find.text('En galería'), findsOneWidget);
      expect(find.text('Guardar en galería'), findsNothing);
    },
  );

  testWidgets('eliminar pide confirmar y cancelar conserva el video', (
    tester,
  ) async {
    await _open(tester, _args);

    await tester.tap(find.text('Eliminar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('¿Eliminar este video?'), findsOneWidget);
    expect(find.text('Se borrará de SaveTic para siempre.'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('¿Eliminar este video?'), findsNothing);
    expect(find.text('@cocinaconlucia'), findsOneWidget);
  });

  testWidgets('confirmar la eliminación cierra el reproductor', (tester) async {
    await _open(tester, _args);

    await tester.tap(find.text('Eliminar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // El botón de la confirmación comparte texto con la acción del reproductor.
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      ),
    );
    await tester.pump();
    // Las transiciones de página de Flutter 3.47 duran más que las de 3.29.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('@cocinaconlucia'), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('si el video no se puede abrir lo dice con palabras', (
    tester,
  ) async {
    await _open(tester, _args, failOnCreate: true);

    expect(find.text('No pudimos reproducir este video.'), findsOneWidget);
  });
}
