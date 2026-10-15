import '../../../../core/error/failure.dart';
import '../entities/cancel_signal.dart';
import '../entities/tiktok_video.dart';
import 'package:dartz/dartz.dart';

abstract class TiktokVideoBaseRepo {
  Future<Either<Failure, TikTokVideo>> getVideo(String videoLink);

  /// Peso del archivo en bytes, o nulo si el servidor no lo informa.
  Future<Either<Failure, int?>> getFileSize(String url);

  Future<Either<Failure, String>> saveVideo({
    required String videoLink,
    required String savePath,
    void Function(int received, int total)? onProgress,
    CancelSignal? cancelSignal,
  });
}
