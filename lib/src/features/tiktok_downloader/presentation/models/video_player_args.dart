/// Lo que el reproductor necesita saber del video que va a abrir.
class VideoPlayerArgs {
  const VideoPlayerArgs({
    required this.path,
    this.title,
    this.authorHandle,
    this.inGallery = false,
    this.files = const [],
  });

  final String path;

  /// Título y autor, solo si se conocen: los videos guardados de antes
  /// no los tienen.
  final String? title;
  final String? authorHandle;

  /// Si ya hay una copia en la galería.
  final bool inGallery;

  /// Las piezas, si es un slideshow o carrusel: [path] es entonces la carpeta.
  final List<String> files;

  bool get isGallery => files.isNotEmpty;

  bool get isAudio => path.toLowerCase().endsWith('.mp3');
}
