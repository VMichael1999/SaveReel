import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../domain/entities/saved_video.dart';

typedef RootPathProvider = Future<String> Function();
typedef ThumbnailMaker = Future<String?> Function(String videoPath);
typedef DurationReader = Future<int?> Function(String videoPath);

abstract class SavedVideosBaseLocalDataSource {
  Future<List<SavedVideo>> list();

  Future<String?> thumbnailFor(String path);

  Future<int?> probeDuration(String path);

  Future<void> record(SavedVideoMetadata metadata);

  Future<void> forget(String path);
}

/// Lee la carpeta de descargas. Los datos de cada video viven en un archivo
/// `<video>.json` a su lado, para no depender de una base de datos.
class SavedVideosLocalDataSource implements SavedVideosBaseLocalDataSource {
  SavedVideosLocalDataSource({
    required this.rootPath,
    ThumbnailMaker? makeThumbnail,
    DurationReader? readDuration,
  }) : _makeThumbnail = makeThumbnail ?? _defaultThumbnail,
       _readDuration = readDuration ?? _defaultDuration;

  final RootPathProvider rootPath;
  final ThumbnailMaker _makeThumbnail;
  final DurationReader _readDuration;

  static const _extensions = ['.mp4', '.mp3'];

  File _sidecar(String path) => File('$path.json');

  @override
  Future<List<SavedVideo>> list() async {
    final dir = Directory(await rootPath());
    if (!await dir.exists()) return [];

    final videos = <SavedVideo>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final lower = entity.path.toLowerCase();
      if (!_extensions.any(lower.endsWith)) continue;
      final stat = await entity.stat();
      final meta = await _readMetadata(entity.path);
      videos.add(
        SavedVideo(
          path: entity.path,
          sizeBytes: stat.size,
          modified: stat.modified,
          title: meta?['title'] as String?,
          authorHandle: meta?['author'] as String?,
          durationSeconds: meta?['durationSeconds'] as int?,
        ),
      );
    }
    videos.sort((a, b) => b.modified.compareTo(a.modified));
    return videos;
  }

  Future<Map<String, dynamic>?> _readMetadata(String path) async {
    final file = _sidecar(path);
    if (!await file.exists()) return null;
    try {
      final data = jsonDecode(await file.readAsString());
      return data is Map<String, dynamic> ? data : null;
    } catch (_) {
      // Un archivo de datos dañado no debe esconder el video.
      return null;
    }
  }

  Future<void> _writeMetadata(String path, Map<String, dynamic> data) =>
      _sidecar(path).writeAsString(jsonEncode(data));

  @override
  Future<void> record(SavedVideoMetadata metadata) {
    final current = <String, dynamic>{
      if (metadata.title != null) 'title': metadata.title,
      if (metadata.authorHandle != null) 'author': metadata.authorHandle,
      if (metadata.durationSeconds != null)
        'durationSeconds': metadata.durationSeconds,
    };
    return _writeMetadata(metadata.path, current);
  }

  @override
  Future<int?> probeDuration(String path) async {
    final seconds = await _readDuration(path);
    if (seconds == null) return null;
    final data = await _readMetadata(path) ?? <String, dynamic>{};
    data['durationSeconds'] = seconds;
    await _writeMetadata(path, data);
    return seconds;
  }

  @override
  Future<void> forget(String path) async {
    final file = _sidecar(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<String?> thumbnailFor(String path) => _makeThumbnail(path);

  static Future<String?> _defaultThumbnail(String videoPath) async {
    if (videoPath.toLowerCase().endsWith('.mp3')) return null;
    final cache = Directory('${(await getTemporaryDirectory()).path}/portadas');
    if (!await cache.exists()) await cache.create(recursive: true);
    final name = videoPath.split(Platform.pathSeparator).last;
    final target = File('${cache.path}/$name.png');
    if (await target.exists()) return target.path;
    return VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: target.path,
      imageFormat: ImageFormat.PNG,
      quality: 50,
      maxWidth: 360,
    );
  }

  static Future<int?> _defaultDuration(String videoPath) async {
    final controller = VideoPlayerController.file(File(videoPath));
    try {
      await controller.initialize();
      final seconds = controller.value.duration.inSeconds;
      return seconds > 0 ? seconds : null;
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }
}
