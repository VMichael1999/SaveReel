import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/error/failure.dart';
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

const _video = TikTokVideo(
  code: 0,
  msg: 'success',
  processedTime: 0.4,
  videoData: VideoData(
    id: '42',
    duration: 34,
    title: 'Lomo saltado',
    originCover: '',
    playVideo: 'https://ejemplo.pe/limpio',
    wmPlayVideo: 'https://ejemplo.pe/con-marca',
    music: 'https://ejemplo.pe/audio',
    playCount: 1,
    downloadCount: 1,
  ),
);

/// Repositorio cuyo guardado se controla desde cada prueba.
class _ScriptedRepo implements TiktokVideoBaseRepo {
  _ScriptedRepo(this.onSave);

  final Future<Either<Failure, String>> Function(
    void Function(int, int)? onProgress,
    CancelSignal? signal,
  )
  onSave;
  int saveCalls = 0;

  @override
  Future<Either<Failure, TikTokVideo>> getVideo(String videoLink) async =>
      const Right(_video);

  @override
  Future<Either<Failure, int?>> getFileSize(String url) async =>
      const Right(null);

  @override
  Future<Either<Failure, String>> saveVideo({
    required String videoLink,
    required String savePath,
    void Function(int received, int total)? onProgress,
    CancelSignal? cancelSignal,
  }) {
    saveCalls++;
    return onSave(onProgress, cancelSignal);
  }
}

DownloaderBloc _bloc(_ScriptedRepo repo) => DownloaderBloc(
  getVideoUseCase: GetVideoUseCase(videoRepo: repo),
  saveVideoUseCase: SaveVideoUseCase(videoRepo: repo),
  getFileSizeUseCase: GetFileSizeUseCase(videoRepo: repo),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('savetic_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('guarda el avance de cada descarga mientras baja', () async {
    final gate = Completer<void>();
    final repo = _ScriptedRepo((onProgress, _) async {
      onProgress?.call(50, 100);
      await gate.future;
      return const Right('ok');
    });
    final bloc = _bloc(repo);

    bloc.add(const DownloaderSaveVideo(tikTokVideo: _video));
    await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoProgress);

    expect(bloc.newDownloads.single.status, DownloadStatus.downloading);
    expect(bloc.newDownloads.single.progress, 0.5);
    expect(bloc.newDownloads.single.startedAt, isNotNull);

    gate.complete();
    await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoSuccess);
    expect(bloc.newDownloads.single.status, DownloadStatus.success);
    await bloc.close();
  });

  test(
    'cancelar quita la descarga de la lista y borra el archivo parcial',
    () async {
      final repo = _ScriptedRepo((onProgress, signal) async {
        final cancelled = Completer<void>();
        signal!.onCancel(cancelled.complete);
        onProgress?.call(10, 100);
        await cancelled.future;
        return const Left(CancelRequestFailure());
      });
      final bloc = _bloc(repo);

      bloc.add(const DownloaderSaveVideo(tikTokVideo: _video));
      await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoProgress);
      final path = bloc.newDownloads.single.path;
      await File(path).writeAsString('parcial');

      bloc.add(DownloaderCancelVideo(path));
      await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoCancelled);

      expect(bloc.newDownloads, isEmpty);
      expect(await File(path).exists(), isFalse);
      await bloc.close();
    },
  );

  test('una descarga fallida guarda el motivo y se puede reintentar', () async {
    var attempt = 0;
    final repo = _ScriptedRepo((_, __) async {
      attempt++;
      return attempt == 1
          ? const Left(ConnectTimeOutFailure())
          : const Right('ok');
    });
    final bloc = _bloc(repo);

    bloc.add(
      const DownloaderSaveVideo(
        tikTokVideo: _video,
        format: DownloadFormat.noWatermark,
      ),
    );
    await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoFailure);

    final failed = bloc.newDownloads.single;
    expect(failed.status, DownloadStatus.error);
    expect(failed.failureMessage, const ConnectTimeOutFailure().message);

    bloc.add(DownloaderRetryVideo(failed.path));
    await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoSuccess);

    expect(repo.saveCalls, 2);
    expect(bloc.newDownloads, hasLength(1));
    expect(bloc.newDownloads.single.status, DownloadStatus.success);
    expect(bloc.newDownloads.single.failureMessage, isNull);
    await bloc.close();
  });

  test('bajar dos formatos del mismo video no se pisan', () async {
    final repo = _ScriptedRepo((_, __) async => const Right('ok'));
    final bloc = _bloc(repo);

    bloc.add(const DownloaderSaveVideo(tikTokVideo: _video));
    await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoSuccess);
    bloc.add(
      const DownloaderSaveVideo(
        tikTokVideo: _video,
        format: DownloadFormat.audio,
      ),
    );
    await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoSuccess);

    expect(bloc.newDownloads, hasLength(2));
    await bloc.close();
  });

  test('eliminar borra el archivo y quita el video de las listas', () async {
    final repo = _ScriptedRepo((_, __) async => const Right('ok'));
    final bloc = _bloc(repo);

    bloc.add(const DownloaderSaveVideo(tikTokVideo: _video));
    await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoSuccess);
    final path = bloc.newDownloads.single.path;
    await File(path).writeAsString('video');

    bloc.add(DownloaderDeleteVideo(path));
    await bloc.stream.firstWhere((s) => s is DownloaderVideoDeleted);

    expect(bloc.newDownloads, isEmpty);
    expect(await File(path).exists(), isFalse);
    expect(bloc.isInGallery(path), isFalse);
    await bloc.close();
  });
}
