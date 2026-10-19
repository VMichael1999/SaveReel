import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/tiktok_video.dart';
import '../../models/download_format.dart';

/// Qué muestra la mitad derecha del inicio cuando el iPhone Duo está abierto
/// en horizontal.
@immutable
class DuoPane {
  const DuoPane.none() : video = null, format = null, downloads = false;
  const DuoPane.preview(this.video, [this.format]) : downloads = false;
  const DuoPane.downloads() : video = null, format = null, downloads = true;

  /// La vista previa que se muestra, con el formato ya elegido.
  final TikTokVideo? video;
  final DownloadFormat? format;

  /// Si se muestran las descargas.
  final bool downloads;

  bool get isNone => video == null && !downloads;
}

/// Vive por encima del cambio de diseño para que abrir o cerrar el teléfono
/// no pierda lo que había: la vista previa con su formato, o las descargas.
class DuoPaneCubit extends Cubit<DuoPane> {
  DuoPaneCubit() : super(const DuoPane.none());

  void showPreview(TikTokVideo video, [DownloadFormat? format]) =>
      emit(DuoPane.preview(video, format));

  void setFormat(DownloadFormat format) {
    final video = state.video;
    if (video != null) emit(DuoPane.preview(video, format));
  }

  void showDownloads() => emit(const DuoPane.downloads());

  void clear() => emit(const DuoPane.none());
}
