import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/saved_videos_base_repo.dart';

class ForgetSavedVideoUseCase extends BaseUseCase<Unit, String> {
  final SavedVideosBaseRepo repo;

  ForgetSavedVideoUseCase({required this.repo});

  @override
  Future<Either<Failure, Unit>> call(String params) => repo.forget(params);
}
