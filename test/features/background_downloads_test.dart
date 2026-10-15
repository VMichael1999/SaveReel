import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/error/failure.dart';
import 'package:savetic/src/core/helpers/background_downloads.dart';
import 'package:savetic/src/core/utils/app_enums.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/cancel_signal.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/tiktok_video.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/video_data.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/repositories/tiktok_video_base_repo.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_file_size_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/save_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/downloader_bloc/downloader_bloc.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/models/download_format.dart';

TikTokVideo _video(String id, String title) => TikTokVideo(
  code: 0,
  msg: 'success',
  processedTime: 0,
  videoData: VideoData(
    id: id,
    duration: 10,
    title: title,
    originCover: '',
    playVideo: 'https://ejemplo.pe/$id',
    wmPlayVideo: 'https://ejemplo.pe/$id-wm',
    music: '',
    playCount: 0,
    downloadCount: 0,
  ),
);

class _RecordingBackground implements BackgroundDownloads {
  final List<BackgroundSnapshot> syncs = [];
  final List<(String, bool)> finished = [];

  @override
  Future<void> sync(BackgroundSnapshot snapshot) async => syncs.add(snapshot);

  @override
  Future<void> notifyFinished({
    required String title,
    required bool success,
  }) async => finished.add((title, success));
}

/// Cada llamada a guardar recibe el siguiente resultado de la lista (el
/// último se repite) y puede quedarse esperando a que se libere.
class _Repo implements TiktokVideoBaseRepo {
  _Repo(this.results, {this.hold});

  final List<Either<Failure, String>> results;
  Completer<void>? hold;
  int calls = 0;

  @override
  Future<Either<Failure, TikTokVideo>> getVideo(String videoLink) async =>
      Right(_video('1', 'x'));

  @override
  Future<Either<Failure, int?>> getFileSize(String url) async =>
      const Right(null);

  @override
  Future<Either<Failure, String>> saveVideo({
    required String videoLink,
    required String savePath,
    void Function(int received, int total)? onProgress,
    CancelSignal? cancelSignal,
  }) async {
    final index = calls++;
    onProgress?.call(50, 100);
    if (hold != null) await hold!.future;
    return results[index.clamp(0, results.length - 1)];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('segundo_plano');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
  });

  tearDown(() => tempDir.delete(recursive: true));

  DownloaderBloc bloc(_Repo repo, _RecordingBackground background) =>
      DownloaderBloc(
        getVideoUseCase: GetVideoUseCase(videoRepo: repo),
        saveVideoUseCase: SaveVideoUseCase(videoRepo: repo),
        getFileSizeUseCase: GetFileSizeUseCase(videoRepo: repo),
        shouldSaveToGallery: () => false,
        background: background,
        autoRetryDelay: Duration.zero,
      );

  DownloaderSaveVideo save(String id, String title) => DownloaderSaveVideo(
    tikTokVideo: _video(id, title),
    format: DownloadFormat.noWatermark,
  );

  Future<void> done(DownloaderBloc b) =>
      b.stream.firstWhere((s) => s is DownloaderSaveVideoSuccess);

  test(
    'informa de la descarga en curso y al terminar la da por acabada',
    () async {
      final background = _RecordingBackground();
      final repo = _Repo([const Right('ok')]);
      final b = bloc(repo, background);

      b.add(save('1', 'Lomo saltado'));
      await done(b);

      expect(background.syncs.first.count, 1);
      expect(background.syncs.first.title, 'Lomo saltado');
      expect(background.syncs.any((s) => s.percent == 50), isTrue);
      expect(background.syncs.last, BackgroundSnapshot.none);
      await b.close();
    },
  );

  test('con varias descargas a la vez resume cuántas son', () async {
    final background = _RecordingBackground();
    final hold = Completer<void>();
    final repo = _Repo([const Right('ok')], hold: hold);
    final b = bloc(repo, background);

    b.add(save('1', 'Uno'));
    b.add(save('2', 'Dos'));
    await b.stream.firstWhere((s) => s is DownloaderSaveVideoProgress);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(background.syncs.last.count, 2);
    expect(background.syncs.last.title, '2 descargas');

    hold.complete();
    await b.stream.firstWhere((s) => s is DownloaderSaveVideoSuccess);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(background.syncs.last, BackgroundSnapshot.none);
    await b.close();
  });

  test('avisa al terminar solo si la app estaba fuera de pantalla', () async {
    final background = _RecordingBackground();
    final repo = _Repo([const Right('ok')]);
    final b = bloc(repo, background);

    b.add(save('1', 'Primero'));
    await done(b);
    expect(background.finished, isEmpty);

    b.add(const DownloaderAppLifecycleChanged(away: true));
    b.add(save('2', 'Segundo'));
    await done(b);
    expect(background.finished, [('Segundo', true)]);
    await b.close();
  });

  test(
    'un corte pasajero con la app fuera se retoma solo, sin error',
    () async {
      final background = _RecordingBackground();
      final repo = _Repo([
        const Left(NoInternetConnectionFailure()),
        const Right('ok'),
      ]);
      final b = bloc(repo, background);
      final states = <DownloaderState>[];
      b.stream.listen(states.add);

      b.add(const DownloaderAppLifecycleChanged(away: true));
      b.add(save('1', 'Largo'));
      await done(b);

      expect(repo.calls, 2);
      expect(states.whereType<DownloaderSaveVideoFailure>(), isEmpty);
      expect(b.newDownloads.single.status, DownloadStatus.success);
      await b.close();
    },
  );

  test('un corte justo al volver también se retoma solo', () async {
    final background = _RecordingBackground();
    final repo = _Repo([
      const Left(ConnectTimeOutFailure()),
      const Right('ok'),
    ]);
    final b = bloc(repo, background);

    b.add(const DownloaderAppLifecycleChanged(away: true));
    b.add(const DownloaderAppLifecycleChanged(away: false));
    b.add(save('1', 'Largo'));
    await done(b);

    expect(repo.calls, 2);
    await b.close();
  });

  test(
    'con la app a la vista un fallo se muestra y no se reintenta solo',
    () async {
      final background = _RecordingBackground();
      final repo = _Repo([const Left(NoInternetConnectionFailure())]);
      final b = bloc(repo, background);

      b.add(save('1', 'Largo'));
      await b.stream.firstWhere((s) => s is DownloaderSaveVideoFailure);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.calls, 1);
      expect(b.newDownloads.single.status, DownloadStatus.error);
      await b.close();
    },
  );

  test(
    'un fallo que no es pasajero no se reintenta aunque esté fuera',
    () async {
      final background = _RecordingBackground();
      final repo = _Repo([const Left(NotFoundFailure())]);
      final b = bloc(repo, background);

      b.add(const DownloaderAppLifecycleChanged(away: true));
      b.add(save('1', 'Borrado'));
      await b.stream.firstWhere((s) => s is DownloaderSaveVideoFailure);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.calls, 1);
      expect(background.finished, [('Borrado', false)]);
      await b.close();
    },
  );

  test('deja de insistir tras tres reintentos automáticos', () async {
    final background = _RecordingBackground();
    final repo = _Repo([const Left(ServerFailure())]);
    final b = bloc(repo, background);

    b.add(const DownloaderAppLifecycleChanged(away: true));
    b.add(save('1', 'Largo'));
    await b.stream.firstWhere((s) => s is DownloaderSaveVideoFailure);

    expect(repo.calls, 4); // el intento inicial y tres reintentos
    expect(b.newDownloads.single.status, DownloadStatus.error);
    await b.close();
  });
}
