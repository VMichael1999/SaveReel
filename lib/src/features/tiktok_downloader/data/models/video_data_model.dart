import '../../domain/entities/video_data.dart';

class VideoDataModel extends VideoData {
  const VideoDataModel({
    required super.id,
    required super.duration,
    required super.title,
    required super.originCover,
    required super.playVideo,
    required super.wmPlayVideo,
    required super.music,
    required super.playCount,
    required super.downloadCount,
    super.authorHandle,
    super.playBytes,
    super.wmPlayBytes,
  });

  /// Servidor al que apuntan las rutas relativas que a veces devuelve el servicio.
  static const String _relativeBase = 'https://www.tikwm.com';

  factory VideoDataModel.fromJson(Map<String, dynamic> json) {
    return VideoDataModel(
      id: '${json["id"]}',
      duration: _asInt(json["duration"]) ?? 0,
      title: json["title"] as String? ?? '',
      originCover: _absolute(json["origin_cover"] ?? json["cover"]),
      playVideo: _absolute(json["play"]),
      wmPlayVideo: _absolute(json["wmplay"]),
      music: _absolute(json["music"]),
      playCount: _asInt(json["play_count"]) ?? 0,
      downloadCount: _asInt(json["download_count"]) ?? 0,
      authorHandle: _readAuthorHandle(json["author"]),
      playBytes: _asInt(json["size"]),
      wmPlayBytes: _asInt(json["wm_size"]),
    );
  }

  static int? _asInt(dynamic value) => switch (value) {
    int v => v,
    num v => v.toInt(),
    String v => int.tryParse(v),
    _ => null,
  };

  /// Algunos servicios devuelven rutas como `/video/media/play/…`.
  static String _absolute(dynamic url) {
    if (url is! String || url.isEmpty) return '';
    return url.startsWith('/') ? '$_relativeBase$url' : url;
  }

  static String? _readAuthorHandle(dynamic author) {
    if (author is! Map) return null;
    final handle = author["unique_id"];
    return handle is String && handle.isNotEmpty ? handle : null;
  }
}
