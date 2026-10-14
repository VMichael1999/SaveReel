import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/saved_videos_base_repo.dart';

class ClearThumbnailCacheUseCase extends BaseUseCase<Unit, NoParams> {
  final SavedVideosBaseRepo repo;

  ClearThumbnailCacheUseCase({required this.repo});

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => repo.clearThumbnailCache();
}
