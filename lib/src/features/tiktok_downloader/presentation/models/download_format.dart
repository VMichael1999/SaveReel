import '../../domain/entities/video_data.dart';

/// Las tres formas de guardar un video que ofrece la vista previa.
enum DownloadFormat {
  /// Versión con el nombre del autor visible. Es la predeterminada.
  withCredits,

  /// Versión limpia, para verla sin conexión.
  noWatermark,

  /// Solo la música.
  audio,

  /// Todas las fotos (y videos) de un slideshow o carrusel, en una carpeta.
  gallery;

  bool get isAudio => this == DownloadFormat.audio;

  /// Enlace de descarga según el formato.
  String urlOf(VideoData video) => switch (this) {
        DownloadFormat.withCredits => video.wmPlayVideo,
        DownloadFormat.noWatermark => video.playVideo,
        DownloadFormat.audio => video.music,
        DownloadFormat.gallery =>
          video.gallery.isEmpty ? '' : video.gallery.first.url,
      };

  bool isAvailableIn(VideoData video) =>
      this == DownloadFormat.gallery ? video.isGallery : urlOf(video).isNotEmpty;

  /// Nombre del archivo, sin carpeta. Cada formato tiene el suyo para que
  /// bajar uno no pise a otro.
  String fileNameFor(String videoId) => switch (this) {
        DownloadFormat.withCredits => '$videoId.mp4',
        DownloadFormat.noWatermark => '${videoId}_sin_marca.mp4',
        DownloadFormat.audio => '$videoId.mp3',
        DownloadFormat.gallery => videoId,
      };
}
