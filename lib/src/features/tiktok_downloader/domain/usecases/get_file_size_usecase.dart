import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/tiktok_video_base_repo.dart';

class GetFileSizeUseCase extends BaseUseCase<int?, String> {
  final TiktokVideoBaseRepo videoRepo;

  GetFileSizeUseCase({required this.videoRepo});

  @override
  Future<Either<Failure, int?>> call(String params) =>
      videoRepo.getFileSize(params);
}
