import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/saved_video.dart';
import '../repositories/saved_videos_base_repo.dart';

class GetSavedVideosUseCase extends BaseUseCase<List<SavedVideo>, NoParams> {
  final SavedVideosBaseRepo repo;

  GetSavedVideosUseCase({required this.repo});

  @override
  Future<Either<Failure, List<SavedVideo>>> call(NoParams params) =>
      repo.list();
}
