import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/features/tiktok_downloader/data/datasources/local/saved_videos_local_data_source.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/saved_video.dart';

void main() {
  late Directory dir;
  late SavedVideosLocalDataSource source;
  int? probedSeconds = 34;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('biblioteca');
    probedSeconds = 34;
    source = SavedVideosLocalDataSource(
      rootPath: () async => dir.path,
      makeThumbnail: (path) async => '$path.png',
      readDuration: (_) async => probedSeconds,
    );
  });

  tearDown(() => dir.delete(recursive: true));

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
}
