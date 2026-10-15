import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/utils/video_link.dart';
import 'package:savetic/src/features/tiktok_downloader/data/datasources/local/saved_videos_local_data_source.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/saved_video.dart';

void main() {
  late Directory dir;
  late Directory cache;
  late SavedVideosLocalDataSource source;
  int? probedSeconds = 34;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('biblioteca');
    cache = Directory('${dir.path}_portadas');
    probedSeconds = 34;
    source = SavedVideosLocalDataSource(
      rootPath: () async => dir.path,
      makeThumbnail: (path) async => '$path.png',
      readDuration: (_) async => probedSeconds,
      cacheDirectory: () async => cache,
    );
  });

  tearDown(() async {
    await dir.delete(recursive: true);
    if (await cache.exists()) await cache.delete(recursive: true);
  });

  Future<File> touch(String name, {DateTime? modified}) async {
    final file = await File('${dir.path}/$name').create();
    await file.writeAsString('x');
    if (modified != null) await file.setLastModified(modified);
    return file;
  }

  test(
    'lista videos y audios, ignora otros archivos y ordena del más nuevo',
    () async {
      await touch('viejo.mp4', modified: DateTime(2026, 1, 1));
      await touch('nuevo.mp4', modified: DateTime(2026, 6, 1));
      await touch('musica.mp3', modified: DateTime(2026, 3, 1));
      await touch('notas.txt');
      await touch('nuevo.mp4.json');

      final videos = await source.list();

      expect(videos.map((v) => v.path.split('/').last), [
        'nuevo.mp4',
        'musica.mp3',
        'viejo.mp4',
      ]);
      expect(videos[1].isAudio, isTrue);
    },
  );

  test('una carpeta que no existe da una lista vacía', () async {
    await dir.delete(recursive: true);
    expect(await source.list(), isEmpty);
    await dir.create();
  });

  test('anota título, autor y duración y los devuelve al listar', () async {
    final file = await touch('v.mp4');
    await source.record(
      SavedVideoMetadata(
        path: file.path,
        title: 'Lomo saltado',
        authorHandle: 'cocinaconlucia',
        durationSeconds: 34,
      ),
    );

    final video = (await source.list()).single;

    expect(video.title, 'Lomo saltado');
    expect(video.authorHandle, 'cocinaconlucia');
    expect(video.durationSeconds, 34);
  });

  test('anota la red y los archivos sin dato cuentan como de TikTok', () async {
    final reel = await touch('reel.mp4');
    final viejo = await touch('viejo.mp4');
    await source.record(
      SavedVideoMetadata(path: reel.path, network: VideoNetwork.instagram),
    );

    final videos = {for (final v in await source.list()) v.path: v};

    expect(videos[reel.path]!.network, VideoNetwork.instagram);
    expect(videos[viejo.path]!.network, isNull);
    expect(videos[viejo.path]!.source, VideoNetwork.tiktok);
  });

  test(
    'una duración de 0 se trata como desconocida y se lee del archivo',
    () async {
      final file = await touch('reel.mp4');
      await source.record(
        SavedVideoMetadata(path: file.path, durationSeconds: 0),
      );
      // Archivo anotado por una versión anterior, con el 0 ya guardado.
      await File('${file.path}.json').writeAsString('{"durationSeconds":0}');

      expect((await source.list()).single.durationSeconds, isNull);

      expect(await source.probeDuration(file.path), 34);
      expect((await source.list()).single.durationSeconds, 34);
    },
  );

  Future<Directory> gallery(String name, List<String> files) async {
    final folder = await Directory('${dir.path}/$name').create();
    for (final file in files) {
      await File('${folder.path}/$file').writeAsString('xx');
    }
    return folder;
  }

  test(
    'una carpeta de galería se lista como un solo elemento ordenado',
    () async {
      final folder = await gallery('C9z', [
        '03.webp',
        '01.jpg',
        '02.mp4',
        'x.txt',
      ]);
      await source.record(
        SavedVideoMetadata(
          path: folder.path,
          title: 'Viaje',
          authorHandle: 'viajes.peru',
          network: VideoNetwork.instagram,
        ),
      );
      await touch('suelto.mp4');

      final videos = {for (final v in await source.list()) v.path: v};
      final item = videos[folder.path]!;

      expect(item.isGallery, isTrue);
      expect(item.files.map((f) => f.split('/').last), [
        '01.jpg',
        '02.mp4',
        '03.webp',
      ]);
      expect(item.sizeBytes, 6); // tres piezas de 2 bytes; x.txt no cuenta
      expect(item.title, 'Viaje');
      expect(item.authorHandle, 'viajes.peru');
      expect(item.source, VideoNetwork.instagram);
      expect(item.isAudio, isFalse);
      expect(videos.length, 2); // la galería y el video suelto
    },
  );

  test('una carpeta sin fotos ni videos no aparece', () async {
    await gallery('vacia', ['notas.txt']);
    await Directory('${dir.path}/otra').create();

    expect(await source.list(), isEmpty);
  });

  test('olvidar una galería borra su archivo de datos', () async {
    final folder = await gallery('C9z', ['01.jpg']);
    await source.record(SavedVideoMetadata(path: folder.path, title: 'x'));
    expect(File('${folder.path}.json').existsSync(), isTrue);

    await source.forget(folder.path);

    expect(File('${folder.path}.json').existsSync(), isFalse);
  });

  test('la portada de una foto es la foto misma', () async {
    final real = SavedVideosLocalDataSource(
      rootPath: () async => dir.path,
      cacheDirectory: () async => cache,
    );
    expect(await real.thumbnailFor('/x/01.jpg'), '/x/01.jpg');
    expect(await real.thumbnailFor('/x/02.webp'), '/x/02.webp');
    expect(await real.thumbnailFor('/x/musica.mp3'), isNull);
  });

  test('un archivo de datos dañado no esconde el video', () async {
    final file = await touch('v.mp4');
    await File('${file.path}.json').writeAsString('{no es json');

    final video = (await source.list()).single;

    expect(video.title, isNull);
    expect(video.durationSeconds, isNull);
  });

  test('leer la duración la anota sin perder lo que ya había', () async {
    final file = await touch('v.mp4');
    await source.record(SavedVideoMetadata(path: file.path, title: 'Mi video'));

    expect(await source.probeDuration(file.path), 34);

    final video = (await source.list()).single;
    expect(video.title, 'Mi video');
    expect(video.durationSeconds, 34);
  });

  test('si no se puede leer la duración no anota nada', () async {
    final file = await touch('v.mp4');
    probedSeconds = null;

    expect(await source.probeDuration(file.path), isNull);
    expect(File('${file.path}.json').existsSync(), isFalse);
  });

  test('olvidar quita los datos pero no el archivo', () async {
    final file = await touch('v.mp4');
    await source.record(SavedVideoMetadata(path: file.path, title: 'x'));

    await source.forget(file.path);

    expect(File('${file.path}.json').existsSync(), isFalse);
    expect(file.existsSync(), isTrue);
  });

  test('sin portadas el caché pesa cero', () async {
    expect(await source.thumbnailCacheSize(), 0);
  });

  test('suma el peso de las portadas y se puede vaciar', () async {
    await cache.create(recursive: true);
    await File('${cache.path}/a.png').writeAsBytes(List.filled(1000, 1));
    await File('${cache.path}/b.png').writeAsBytes(List.filled(500, 1));

    expect(await source.thumbnailCacheSize(), 1500);

    await source.clearThumbnailCache();

    expect(await source.thumbnailCacheSize(), 0);
    expect(cache.existsSync(), isFalse);
  });

  test('vaciar un caché que no existe no falla', () async {
    await source.clearThumbnailCache();

    expect(await source.thumbnailCacheSize(), 0);
  });
}
