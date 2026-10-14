/// Lo que el reproductor necesita saber del video que va a abrir.
class VideoPlayerArgs {
  const VideoPlayerArgs({
    required this.path,
    this.title,
    this.authorHandle,
    this.inGallery = false,
  });

  final String path;

  /// Título y autor, solo si se conocen: los videos guardados de antes
  /// no los tienen.
  final String? title;
  final String? authorHandle;

  /// Si ya hay una copia en la galería.
  final bool inGallery;

  bool get isAudio => path.toLowerCase().endsWith('.mp3');
}
