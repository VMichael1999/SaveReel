import 'package:equatable/equatable.dart';

import '../../../../core/utils/video_link.dart';
import 'media_item.dart';

class VideoData extends Equatable {
  final String id;
  final int duration;
  final String title;
  final String originCover;
  final String playVideo;
  final String wmPlayVideo;
  final String music;
  final int playCount;
  final int downloadCount;

  /// Usuario del autor sin la arroba, si la API lo informa.
  final String? authorHandle;

  /// Peso en bytes de cada versión, si el servicio lo informa.
  final int? playBytes;
  final int? wmPlayBytes;

  /// Red de la que viene el video.
  final VideoNetwork network;

  /// Las piezas, cuando la publicación es un slideshow de fotos o un
  /// carrusel. Vacío en un video suelto.
  final List<MediaItem> gallery;

  const VideoData({
    required this.id,
    required this.duration,
    required this.title,
    required this.originCover,
    required this.playVideo,
    required this.wmPlayVideo,
    required this.music,
    required this.playCount,
    required this.downloadCount,
    this.authorHandle,
    this.playBytes,
    this.wmPlayBytes,
    this.network = VideoNetwork.tiktok,
    this.gallery = const [],
  });

  bool get isGallery => gallery.isNotEmpty;
  int get photoCount => gallery.where((m) => !m.isVideo).length;

  @override
  List<Object?> get props => [
    id,
    duration,
    title,
    originCover,
    playVideo,
    wmPlayVideo,
    music,
    playCount,
    downloadCount,
    authorHandle,
    playBytes,
    wmPlayBytes,
    network,
    gallery,
  ];
}
