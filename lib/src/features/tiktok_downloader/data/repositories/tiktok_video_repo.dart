import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/video_link.dart';
import '../../domain/entities/cancel_signal.dart';
import '../../domain/entities/tiktok_video.dart';
import '../../domain/mappers.dart';
import '../../domain/repositories/tiktok_video_base_repo.dart';
import '../datasources/remote/tiktok_video_remote_data_source.dart';
import '../sources/instagram_video_source.dart';
import '../models/tiktok_video_model.dart';

class TiktokVideoRepo implements TiktokVideoBaseRepo {
  final TiktokVideoBaseRemoteDataSource remoteDataSource;

  final InstagramVideoSource instagramSource;

  TiktokVideoRepo({
    required this.remoteDataSource,
    required this.instagramSource,
  });

  @override
  Future<Either<Failure, TikTokVideo>> getVideo(String videoLink) async {
    try {
      if (VideoLink.networkOf(videoLink) == VideoNetwork.instagram) {
        return Right(await _getInstagramVideo(videoLink));
      }
      final TiktokVideoModel video = await remoteDataSource.getVideo(videoLink);
      return Right(video.toDomain());
    } on DioException catch (error) {
      return Left(ErrorHandler.handle(error).failure);
    }
  }

  Future<TikTokVideo> _getInstagramVideo(String videoLink) async {
    final data = await instagramSource.resolve(
      link: videoLink,
      shortcode: VideoLink.shortcodeOf(videoLink)!,
    );
    return TikTokVideo(
      code: data == null ? -1 : 0,
      msg: data == null ? 'No se pudo obtener el video' : 'success',
      processedTime: 0,
      videoData: data,
    );
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
