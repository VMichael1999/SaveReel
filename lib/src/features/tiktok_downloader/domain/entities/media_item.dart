import 'package:equatable/equatable.dart';

/// Una pieza de una publicación con varias: una foto o un video de un
/// carrusel de Instagram, o una foto de un slideshow de TikTok.
class MediaItem extends Equatable {
  const MediaItem({required this.url, this.isVideo = false});

  final String url;
  final bool isVideo;

  /// Extensión del archivo, sacada del enlace; si no se reconoce, la
  /// habitual del tipo (`mp4` para video, `jpg` para foto).
  String get extension {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    final dot = path.lastIndexOf('.');
    final found = dot == -1 ? '' : path.substring(dot + 1);
    const known = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'mp4', 'mov'};
    if (known.contains(found) &&
        (found == 'mp4' || found == 'mov') == isVideo) {
      return found;
    }
    return isVideo ? 'mp4' : 'jpg';
  }

  @override
  List<Object?> get props => [url, isVideo];
}
