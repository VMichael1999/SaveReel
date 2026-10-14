import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecase/base_usecase.dart';
import '../../../domain/entities/saved_video.dart';
import '../../../domain/usecases/clear_thumbnail_cache_usecase.dart';
import '../../../domain/usecases/forget_saved_video_usecase.dart';
import '../../../domain/usecases/get_saved_videos_usecase.dart';
import '../../../domain/usecases/get_thumbnail_cache_size_usecase.dart';
import '../../../domain/usecases/get_video_thumbnail_usecase.dart';
import '../../../domain/usecases/probe_video_duration_usecase.dart';
import '../../../domain/usecases/record_saved_video_usecase.dart';

part 'library_state.dart';

/// Los videos y audios guardados en el teléfono, para la biblioteca y los
/// recientes del inicio.
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit({
    required this.getSavedVideos,
    required this.getThumbnail,
    required this.probeDuration,
    required this.recordSavedVideo,
    required this.forgetSavedVideo,
    required this.getThumbnailCacheSize,
    required this.clearThumbnailCacheUseCase,
  }) : super(const LibraryState());

  final GetSavedVideosUseCase getSavedVideos;
  final GetVideoThumbnailUseCase getThumbnail;
  final ProbeVideoDurationUseCase probeDuration;
  final RecordSavedVideoUseCase recordSavedVideo;
  final ForgetSavedVideoUseCase forgetSavedVideo;
  final GetThumbnailCacheSizeUseCase getThumbnailCacheSize;
  final ClearThumbnailCacheUseCase clearThumbnailCacheUseCase;

  /// Cada carga nueva invalida el recorrido de duraciones de la anterior.
  int _generation = 0;
  final Map<String, Future<String?>> _thumbnails = {};

  Future<void> load() async {
    final generation = ++_generation;
    final result = await getSavedVideos(NoParams());
    if (isClosed || generation != _generation) return;
    final videos = result.fold((_) => <SavedVideo>[], (list) => list);
    emit(LibraryState(status: LibraryStatus.ready, videos: videos));
    await _fillMissingDurations(generation);
  }

  /// Los archivos de versiones anteriores no traen la duración anotada:
  /// se lee del archivo, de a uno, y la lista se actualiza sobre la marcha.
  Future<void> _fillMissingDurations(int generation) async {
    final missing =
        state.videos
            .where((v) => v.durationSeconds == null)
            .map((v) => v.path)
            .toList();
    for (final path in missing) {
      final result = await probeDuration(path);
      if (isClosed || generation != _generation) return;
      final seconds = result.fold((_) => null, (s) => s);
      if (seconds == null) continue;
      emit(
        LibraryState(
          status: LibraryStatus.ready,
          videos: [
            for (final v in state.videos)
              if (v.path == path) v.copyWith(durationSeconds: seconds) else v,
          ],
        ),
      );
    }
  }

  /// Anota título, autor y duración de una descarga recién terminada.
  Future<void> record(SavedVideoMetadata metadata) async {
    await recordSavedVideo(metadata);
    await load();
  }

  /// Olvida un video que se eliminó: quita sus datos y lo saca de la lista.
  Future<void> forget(String path) async {
    await forgetSavedVideo(path);
    _thumbnails.remove(path);
    if (isClosed) return;
    emit(
      LibraryState(
        status: state.status,
        videos: state.videos.where((v) => v.path != path).toList(),
      ),
    );
  }

  /// Peso en bytes de las portadas guardadas en caché.
  Future<int> thumbnailCacheBytes() async =>
      (await getThumbnailCacheSize(NoParams())).fold((_) => 0, (bytes) => bytes);

  /// Borra las portadas en caché; se vuelven a crear cuando hacen falta.
  Future<void> clearThumbnailCache() async {
    await clearThumbnailCacheUseCase(NoParams());
    _thumbnails.clear();
  }

  /// Portada del video; se calcula una sola vez por archivo.
  Future<String?> thumbnailFor(String path) => _thumbnails.putIfAbsent(
    path,
    () async => (await getThumbnail(path)).fold((_) => null, (p) => p),
  );
}
