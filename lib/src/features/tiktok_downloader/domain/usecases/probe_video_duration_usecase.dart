import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/saved_videos_base_repo.dart';

class ProbeVideoDurationUseCase extends BaseUseCase<int?, String> {
  final SavedVideosBaseRepo repo;

  ProbeVideoDurationUseCase({required this.repo});

  @override
  Future<Either<Failure, int?>> call(String params) =>
      repo.probeDuration(params);
}
