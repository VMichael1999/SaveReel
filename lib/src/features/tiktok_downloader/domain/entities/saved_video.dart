import 'package:equatable/equatable.dart';

import '../../../../core/utils/video_link.dart';

/// Un archivo guardado en la app, con los datos que se conocen de él.
class SavedVideo extends Equatable {
  final String path;
  final int sizeBytes;
  final DateTime modified;

  /// Datos que guarda la app al descargar. Los archivos de versiones
  /// anteriores no los tienen.
  final String? title;
  final String? authorHandle;
  final int? durationSeconds;

  /// Red de la que viene. Los archivos de antes de Instagram no lo anotan
  /// y cuentan como de TikTok.
  final VideoNetwork? network;

  /// Las piezas, en orden, cuando es una galería (slideshow o carrusel): su
  /// [path] es la carpeta. Vacío en un video o audio suelto.
  final List<String> files;

  const SavedVideo({
    required this.path,
    required this.sizeBytes,
    required this.modified,
    this.title,
    this.authorHandle,
    this.durationSeconds,
    this.network,
    this.files = const [],
  });

  bool get isGallery => files.isNotEmpty;

  /// Archivo del que sale la portada: la primera pieza de una galería, o el
  /// propio video.
  String get coverPath => isGallery ? files.first : path;

  VideoNetwork get source => network ?? VideoNetwork.tiktok;

  bool get isAudio => path.toLowerCase().endsWith('.mp3');

  SavedVideo copyWith({int? durationSeconds}) => SavedVideo(
    path: path,
    sizeBytes: sizeBytes,
    modified: modified,
    title: title,
    authorHandle: authorHandle,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    network: network,
    files: files,
  );

  @override
  List<Object?> get props => [
    path,
    sizeBytes,
    modified,
    title,
    authorHandle,
    durationSeconds,
    network,
    files,
  ];
}

/// Lo que se anota junto al archivo cuando termina la descarga.
class SavedVideoMetadata extends Equatable {
  final String path;
  final String? title;
  final String? authorHandle;
  final int? durationSeconds;
  final VideoNetwork? network;

  const SavedVideoMetadata({
    required this.path,
    this.title,
    this.authorHandle,
    this.durationSeconds,
    this.network,
  });

  @override
  List<Object?> get props => [
    path,
    title,
    authorHandle,
    durationSeconds,
    network,
  ];
}
