import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/saved_videos_base_repo.dart';

class GetThumbnailCacheSizeUseCase extends BaseUseCase<int, NoParams> {
  final SavedVideosBaseRepo repo;

  GetThumbnailCacheSizeUseCase({required this.repo});

  @override
  Future<Either<Failure, int>> call(NoParams params) => repo.thumbnailCacheSize();
}
