import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/saved_video.dart';
import '../repositories/saved_videos_base_repo.dart';

class RecordSavedVideoUseCase extends BaseUseCase<Unit, SavedVideoMetadata> {
  final SavedVideosBaseRepo repo;

  RecordSavedVideoUseCase({required this.repo});

  @override
  Future<Either<Failure, Unit>> call(SavedVideoMetadata params) =>
      repo.record(params);
}
