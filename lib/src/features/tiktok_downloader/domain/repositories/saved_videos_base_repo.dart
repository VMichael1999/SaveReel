import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/saved_video.dart';

abstract class SavedVideosBaseRepo {
  /// Los archivos guardados, del más nuevo al más viejo.
  Future<Either<Failure, List<SavedVideo>>> list();

  /// Ruta de una imagen de portada del video, o nulo si no se pudo crear.
  Future<Either<Failure, String?>> thumbnailFor(String path);

  /// Duración en segundos leída del archivo. La anota para no repetirlo.
  Future<Either<Failure, int?>> probeDuration(String path);

  Future<Either<Failure, Unit>> record(SavedVideoMetadata metadata);

  /// Quita los datos anotados del archivo (el archivo ya se borró aparte).
  Future<Either<Failure, Unit>> forget(String path);

  Future<Either<Failure, int>> thumbnailCacheSize();

  Future<Either<Failure, Unit>> clearThumbnailCache();
}
