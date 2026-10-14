import 'package:dartz/dartz.dart';
import 'package:savetic/src/core/error/failure.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/saved_video.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/repositories/saved_videos_base_repo.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/forget_saved_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_saved_videos_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_video_thumbnail_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/probe_video_duration_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/record_saved_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';

/// Biblioteca en memoria para las pruebas.
class FakeSavedVideosRepo implements SavedVideosBaseRepo {
  FakeSavedVideosRepo({
    List<SavedVideo> videos = const [],
    Map<String, int?> durations = const {},
  }) : videos = [...videos],
       durations = {...durations};

  final List<SavedVideo> videos;

  /// Duración que "leería" del archivo, por ruta.
  final Map<String, int?> durations;
  final List<SavedVideoMetadata> recorded = [];
  final List<String> forgotten = [];

  @override
  Future<Either<Failure, List<SavedVideo>>> list() async => Right([...videos]);

  @override
  Future<Either<Failure, String?>> thumbnailFor(String path) async =>
      const Right(null);

  @override
  Future<Either<Failure, int?>> probeDuration(String path) async =>
      Right(durations[path]);

  @override
  Future<Either<Failure, Unit>> record(SavedVideoMetadata metadata) async {
    recorded.add(metadata);
    videos.insert(
      0,
      SavedVideo(
        path: metadata.path,
        sizeBytes: 1,
        modified: DateTime.now(),
        title: metadata.title,
        authorHandle: metadata.authorHandle,
        durationSeconds: metadata.durationSeconds,
      ),
    );
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> forget(String path) async {
    forgotten.add(path);
    return const Right(unit);
  }
}

LibraryCubit fakeLibraryCubit([FakeSavedVideosRepo? repo]) {
  final r = repo ?? FakeSavedVideosRepo();
  return LibraryCubit(
    getSavedVideos: GetSavedVideosUseCase(repo: r),
    getThumbnail: GetVideoThumbnailUseCase(repo: r),
    probeDuration: ProbeVideoDurationUseCase(repo: r),
    recordSavedVideo: RecordSavedVideoUseCase(repo: r),
    forgetSavedVideo: ForgetSavedVideoUseCase(repo: r),
  );
}
