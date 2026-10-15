import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/error/failure.dart';
import 'package:savetic/src/core/utils/app_enums.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/cancel_signal.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/media_item.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/tiktok_video.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/video_data.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/repositories/tiktok_video_base_repo.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_file_size_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/save_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/downloader_bloc/downloader_bloc.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/models/download_format.dart';

const _carousel = TikTokVideo(
  code: 0,
  msg: 'success',
  processedTime: 0,
  videoData: VideoData(
    id: 'C9z',
    duration: 0,
    title: 'Viaje a Cusco',
    originCover: '',
    playVideo: '',
    wmPlayVideo: '',
    music: '',
    playCount: 0,
    downloadCount: 0,
    gallery: [
      MediaItem(url: 'https://cdn.ig/uno.jpg?a=1'),
      MediaItem(url: 'https://cdn.ig/dos.mp4', isVideo: true),
      MediaItem(url: 'https://cdn.ig/tres.webp'),
    ],
  ),
);

/// Repositorio que escribe un archivo por pieza y deja controlar cada una.
class _GalleryRepo implements TiktokVideoBaseRepo {
  _GalleryRepo({this.failOn, this.hold});

  /// Número de pieza (desde 1) que debe fallar.
  int? failOn;

  /// Si se da, la pieza 2 se queda esperando a que se complete.
  Completer<void>? hold;
  final List<String> links = [];
  final List<String> paths = [];

  @override
  Future<Either<Failure, TikTokVideo>> getVideo(String videoLink) async =>
      const Right(_carousel);

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
    links.add(videoLink);
    paths.add(savePath);
    final number = links.length;
    onProgress?.call(0, 100);
    if (number == 2 && hold != null) {
      onProgress?.call(50, 100);
      var cancelled = false;
      cancelSignal?.onCancel(() => cancelled = true);
      await hold!.future;
      if (cancelled) return const Left(CancelRequestFailure());
    }
    if (failOn == number) return const Left(ServerFailure());
    await File(savePath).writeAsString('x');
    onProgress?.call(100, 100);
    return const Right('ok');
  }
}

DownloaderBloc _bloc(
  _GalleryRepo repo, {
  bool saveToGallery = true,
  List<String>? gallery,
}) => DownloaderBloc(
  getVideoUseCase: GetVideoUseCase(videoRepo: repo),
  saveVideoUseCase: SaveVideoUseCase(videoRepo: repo),
  getFileSizeUseCase: GetFileSizeUseCase(videoRepo: repo),
  shouldSaveToGallery: () => saveToGallery,
  gallerySaver: (path) async => gallery?.add(path),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('savetic_galeria');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
  });

  tearDown(() => tempDir.delete(recursive: true));

  const event = DownloaderSaveVideo(
    tikTokVideo: _carousel,
    format: DownloadFormat.gallery,
  );

  test('baja cada pieza en orden dentro de una carpeta del video', () async {
    final repo = _GalleryRepo();
    final saved = <String>[];
    final bloc = _bloc(repo, gallery: saved);

    bloc.add(event);
    final done =
        await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoSuccess)
            as DownloaderSaveVideoSuccess;

    expect(done.path.endsWith('/C9z'), isTrue);
    expect(repo.links, [
      'https://cdn.ig/uno.jpg?a=1',
      'https://cdn.ig/dos.mp4',
      'https://cdn.ig/tres.webp',
    ]);
    expect(repo.paths.map((p) => p.split('/').last), [
      '01.jpg',
      '02.mp4',
      '03.webp',
    ]);
    for (final path in repo.paths) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    // Cada pieza va a la galería del teléfono y el conjunto queda marcado.
    expect(saved, repo.paths);
    expect(bloc.isInGallery(done.path), isTrue);

    final item = bloc.newDownloads.single;
    expect(item.status, DownloadStatus.success);
    expect(item.isGallery, isTrue);
    expect(item.unitsDone, 3);
    expect(item.progress, 1);
    await bloc.close();
  });

  test('el avance general promedia las piezas', () async {
    final hold = Completer<void>();
    final repo = _GalleryRepo(hold: hold);
    final bloc = _bloc(repo);

    bloc.add(event);
    await bloc.stream.firstWhere(
      (s) => s is DownloaderSaveVideoProgress && s.receivedBytes == 1500,
    );

    final item = bloc.newDownloads.single;
    expect(item.unitsTotal, 3);
    expect(item.unitsDone, 1);
    expect(item.progress, closeTo(0.5, 0.001));

    hold.complete();
    await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoSuccess);
    await bloc.close();
  });

  test(
    'si una pieza falla, la descarga queda en error y se puede repetir',
    () async {
      final repo = _GalleryRepo(failOn: 2);
      final bloc = _bloc(repo);

      bloc.add(event);
      await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoFailure);

      expect(bloc.newDownloads.single.status, DownloadStatus.error);
      expect(repo.links.length, 2);

      final folder = bloc.newDownloads.single.path;
      repo.failOn = null;
      bloc.add(DownloaderRetryVideo(folder));
      await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoSuccess);

      expect(bloc.newDownloads.single.status, DownloadStatus.success);
      // La pieza 1 ya estaba completa: el segundo intento sigue en la 2.
      expect(repo.links, [
        'https://cdn.ig/uno.jpg?a=1',
        'https://cdn.ig/dos.mp4',
        'https://cdn.ig/dos.mp4',
        'https://cdn.ig/tres.webp',
      ]);
      await bloc.close();
    },
  );

  test('una descarga nueva de una galería ya bajada empieza limpia', () async {
    final repo = _GalleryRepo();
    final bloc = _bloc(repo);
    bloc.add(event);
    await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoSuccess);
    final folder = bloc.newDownloads.single.path;
    await File('$folder/sobra.jpg').writeAsString('x');

    bloc.add(event); // no es un reintento: el usuario la pide otra vez
    await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoSuccess);

    expect(repo.links.length, 6); // las tres piezas, otra vez
    expect(File('$folder/sobra.jpg').existsSync(), isFalse);
    await bloc.close();
  });

  test('cancelar borra la carpeta entera', () async {
    final hold = Completer<void>();
    final repo = _GalleryRepo(hold: hold);
    final bloc = _bloc(repo);

    bloc.add(event);
    await bloc.stream.firstWhere(
      (s) => s is DownloaderSaveVideoProgress && s.receivedBytes == 1500,
    );
    final folder = bloc.newDownloads.single.path;
    expect(Directory(folder).existsSync(), isTrue);

    bloc.add(DownloaderCancelVideo(folder));
    hold.complete();
    await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoCancelled);

    expect(Directory(folder).existsSync(), isFalse);
    expect(bloc.newDownloads, isEmpty);
    await bloc.close();
  });

  test('eliminar una galería borra la carpeta con sus piezas', () async {
    final repo = _GalleryRepo();
    final bloc = _bloc(repo);
    bloc.add(event);
    await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoSuccess);
    final folder = bloc.newDownloads.single.path;

    bloc.add(DownloaderDeleteVideo(folder));
    await bloc.stream.firstWhere((s) => s is DownloaderVideoDeleted);

    expect(Directory(folder).existsSync(), isFalse);
    await bloc.close();
  });

  test(
    'con guardar en galería apagado no toca la galería del teléfono',
    () async {
      final repo = _GalleryRepo();
      final saved = <String>[];
      final bloc = _bloc(repo, saveToGallery: false, gallery: saved);

      bloc.add(event);
      final done =
          await bloc.stream.firstWhere((s) => s is DownloaderSaveVideoSuccess)
              as DownloaderSaveVideoSuccess;

      expect(saved, isEmpty);
      expect(bloc.isInGallery(done.path), isFalse);
      await bloc.close();
    },
  );
}
