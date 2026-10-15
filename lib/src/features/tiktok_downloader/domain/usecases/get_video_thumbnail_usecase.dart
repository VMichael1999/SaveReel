import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/saved_videos_base_repo.dart';

class GetVideoThumbnailUseCase extends BaseUseCase<String?, String> {
  final SavedVideosBaseRepo repo;

  GetVideoThumbnailUseCase({required this.repo});

  @override
  Future<Either<Failure, String?>> call(String params) =>
      repo.thumbnailFor(params);
}
