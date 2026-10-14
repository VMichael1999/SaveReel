import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/saved_video.dart';
import '../../domain/repositories/saved_videos_base_repo.dart';
import '../datasources/local/saved_videos_local_data_source.dart';

class SavedVideosRepo implements SavedVideosBaseRepo {
  final SavedVideosBaseLocalDataSource localDataSource;

  SavedVideosRepo({required this.localDataSource});

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<SavedVideo>>> list() =>
      _guard(localDataSource.list);

  @override
  Future<Either<Failure, String?>> thumbnailFor(String path) =>
      _guard(() => localDataSource.thumbnailFor(path));

  @override
  Future<Either<Failure, int?>> probeDuration(String path) =>
      _guard(() => localDataSource.probeDuration(path));

  @override
  Future<Either<Failure, Unit>> record(SavedVideoMetadata metadata) =>
      _guard(() async {
        await localDataSource.record(metadata);
        return unit;
      });

  @override
  Future<Either<Failure, int>> thumbnailCacheSize() =>
      _guard(localDataSource.thumbnailCacheSize);

  @override
  Future<Either<Failure, Unit>> clearThumbnailCache() => _guard(() async {
        await localDataSource.clearThumbnailCache();
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> forget(String path) => _guard(() async {
    await localDataSource.forget(path);
    return unit;
  });
}
