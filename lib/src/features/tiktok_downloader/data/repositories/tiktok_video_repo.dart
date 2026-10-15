import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/cancel_signal.dart';
import '../../domain/entities/tiktok_video.dart';
import '../../domain/mappers.dart';
import '../../domain/repositories/tiktok_video_base_repo.dart';
import '../datasources/remote/tiktok_video_remote_data_source.dart';
import '../models/tiktok_video_model.dart';

class TiktokVideoRepo implements TiktokVideoBaseRepo {
  final TiktokVideoBaseRemoteDataSource remoteDataSource;

  TiktokVideoRepo({required this.remoteDataSource});

  @override
  Future<Either<Failure, TikTokVideo>> getVideo(String videoLink) async {
    try {
      final TiktokVideoModel video = await remoteDataSource.getVideo(videoLink);
      return Right(video.toDomain());
    } on DioException catch (error) {
      return Left(ErrorHandler.handle(error).failure);
    }
  }

  @override
  Future<Either<Failure, int?>> getFileSize(String url) async {
    try {
      return Right(await remoteDataSource.getFileSize(url));
    } on DioException catch (error) {
      return Left(ErrorHandler.handle(error).failure);
    }
  }

  @override
  Future<Either<Failure, String>> saveVideo({
    required String videoLink,
    required String savePath,
    void Function(int received, int total)? onProgress,
    CancelSignal? cancelSignal,
  }) async {
    try {
      final String message = await remoteDataSource.saveVideo(
        savePath: savePath,
        videoLink: videoLink,
        onProgress: onProgress,
        cancelSignal: cancelSignal,
      );
      return Right(message);
    } on DioException catch (error) {
      return Left(ErrorHandler.handle(error).failure);
    }
  }
}
