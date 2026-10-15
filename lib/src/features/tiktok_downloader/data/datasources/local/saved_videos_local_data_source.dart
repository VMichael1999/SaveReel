import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../../../core/utils/video_link.dart';
import '../../../domain/entities/saved_video.dart';

typedef RootPathProvider = Future<String> Function();
typedef ThumbnailMaker = Future<String?> Function(String videoPath);
typedef DurationReader = Future<int?> Function(String videoPath);
typedef CacheDirectoryProvider = Future<Directory> Function();

abstract class SavedVideosBaseLocalDataSource {
  Future<List<SavedVideo>> list();

  Future<String?> thumbnailFor(String path);

  Future<int?> probeDuration(String path);

  Future<void> record(SavedVideoMetadata metadata);

  Future<void> forget(String path);

  /// Peso en bytes de las portadas guardadas en caché.
  Future<int> thumbnailCacheSize();

  Future<void> clearThumbnailCache();
}

/// Lee la carpeta de descargas. Los datos de cada video viven en un archivo
/// `<video>.json` a su lado, para no depender de una base de datos.
class SavedVideosLocalDataSource implements SavedVideosBaseLocalDataSource {
  SavedVideosLocalDataSource({
    required this.rootPath,
    ThumbnailMaker? makeThumbnail,
    DurationReader? readDuration,
    CacheDirectoryProvider? cacheDirectory,
  }) : _cacheDirectory = cacheDirectory ?? _defaultCacheDirectory,
       _readDuration = readDuration ?? _defaultDuration {
    _makeThumbnail = makeThumbnail ?? _defaultThumbnail;
  }

  final RootPathProvider rootPath;
  late final ThumbnailMaker _makeThumbnail;
  final CacheDirectoryProvider _cacheDirectory;
  final DurationReader _readDuration;

  static const _extensions = ['.mp4', '.mp3'];

  File _sidecar(String path) => File('$path.json');

  @override
  Future<List<SavedVideo>> list() async {
    final dir = Directory(await rootPath());
    if (!await dir.exists()) return [];

    final videos = <SavedVideo>[];
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        final gallery = await _readGallery(entity);
        if (gallery != null) videos.add(gallery);
        continue;
      }
      if (entity is! File) continue;
      final lower = entity.path.toLowerCase();
      if (lower.endsWith('.part')) {
        await _dropStalePartial(entity);
        continue;
      }
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
          durationSeconds: _knownDuration(meta?['durationSeconds']),
          network: VideoNetwork.values.asNameMap()[meta?['network']],
        ),
      );
    }
    videos.sort((a, b) => b.modified.compareTo(a.modified));
    return videos;
  }

  /// Una descarga a medias que nadie retomó en días ya no sirve: el enlace
  /// habrá caducado. Se borra para no ocupar espacio.
  Future<void> _dropStalePartial(File partial) async {
    final age = DateTime.now().difference((await partial.stat()).modified);
    if (age > _partialLifetime) await partial.delete();
  }

  static const _partialLifetime = Duration(days: 3);

  /// Una carpeta con fotos o videos de un slideshow o carrusel se lista como
  /// un solo elemento. Una carpeta sin piezas no cuenta.
  Future<SavedVideo?> _readGallery(Directory folder) async {
    final files = <File>[];
    await for (final entity in folder.list()) {
      if (entity is File && _isMedia(entity.path)) files.add(entity);
    }
    if (files.isEmpty) return null;
    files.sort((a, b) => a.path.compareTo(b.path));
    var size = 0;
    for (final file in files) {
      size += await file.length();
    }
    final stat = await folder.stat();
    final meta = await _readMetadata(folder.path);
    return SavedVideo(
      path: folder.path,
      sizeBytes: size,
      modified: stat.modified,
      title: meta?['title'] as String?,
      authorHandle: meta?['author'] as String?,
      network: VideoNetwork.values.asNameMap()[meta?['network']],
      files: [for (final file in files) file.path],
    );
  }

  static const _galleryExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
    '.mp4',
    '.mov',
  ];

  static bool _isMedia(String path) {
    final lower = path.toLowerCase();
    return _galleryExtensions.any(lower.endsWith);
  }

  /// Una duración de 0 es lo que informa una red que no la sabe (Instagram):
  /// se trata como desconocida para que se lea del archivo.
  static int? _knownDuration(Object? seconds) =>
      seconds is int && seconds > 0 ? seconds : null;

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
      if (_knownDuration(metadata.durationSeconds) != null)
        'durationSeconds': metadata.durationSeconds,
      if (metadata.network != null) 'network': metadata.network!.name,
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

  static Future<Directory> _defaultCacheDirectory() async =>
      Directory('${(await getTemporaryDirectory()).path}/portadas');

  @override
  Future<int> thumbnailCacheSize() async {
    final dir = await _cacheDirectory();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  @override
  Future<void> clearThumbnailCache() async {
    final dir = await _cacheDirectory();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<String?> _defaultThumbnail(String videoPath) async {
    final lower = videoPath.toLowerCase();
    if (lower.endsWith('.mp3')) return null;
    // Una foto es su propia portada.
    if (!lower.endsWith('.mp4') && !lower.endsWith('.mov')) return videoPath;
    final cache = await _cacheDirectory();
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
