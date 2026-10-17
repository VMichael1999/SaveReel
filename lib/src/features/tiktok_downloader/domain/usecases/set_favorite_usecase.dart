import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/saved_videos_base_repo.dart';

class FavoriteParams extends Equatable {
  const FavoriteParams(this.path, this.favorite);

  final String path;
  final bool favorite;

  @override
  List<Object?> get props => [path, favorite];
}

class SetFavoriteUseCase extends BaseUseCase<Unit, FavoriteParams> {
  final SavedVideosBaseRepo repo;

  SetFavoriteUseCase({required this.repo});

  @override
  Future<Either<Failure, Unit>> call(FavoriteParams params) =>
      repo.setFavorite(params.path, params.favorite);
}
