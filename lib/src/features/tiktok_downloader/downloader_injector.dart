import '../../container_injector.dart';
import '../../core/helpers/dir_helper.dart';
import 'data/datasources/local/saved_videos_local_data_source.dart';
import 'data/datasources/remote/tiktok_video_remote_data_source.dart';
import 'data/repositories/saved_videos_repo.dart';
import 'data/repositories/tiktok_video_repo.dart';
import 'domain/repositories/saved_videos_base_repo.dart';
import 'domain/repositories/tiktok_video_base_repo.dart';
import 'domain/usecases/forget_saved_video_usecase.dart';
import 'domain/usecases/get_saved_videos_usecase.dart';
import 'domain/usecases/get_video_thumbnail_usecase.dart';
import 'domain/usecases/probe_video_duration_usecase.dart';
import 'domain/usecases/record_saved_video_usecase.dart';
import 'presentation/bloc/library_cubit/library_cubit.dart';
import 'domain/usecases/get_file_size_usecase.dart';
import 'domain/usecases/get_video_usecase.dart';
import 'domain/usecases/save_video_usecase.dart';
import 'presentation/bloc/downloader_bloc/downloader_bloc.dart';

void initDownloader() {
  // data source
  sl.registerLazySingleton<TiktokVideoBaseRemoteDataSource>(
    () => TiktokVideoRemoteDataSource(dioHelper: sl()),
  );
  // repository
  sl.registerLazySingleton<TiktokVideoBaseRepo>(
    () => TiktokVideoRepo(remoteDataSource: sl(), networkInfo: sl()),
  );
  // use-case
  sl.registerLazySingleton<GetVideoUseCase>(
    () => GetVideoUseCase(videoRepo: sl()),
  );
  sl.registerLazySingleton<GetFileSizeUseCase>(
    () => GetFileSizeUseCase(videoRepo: sl()),
  );
  sl.registerLazySingleton<SaveVideoUseCase>(
    () => SaveVideoUseCase(videoRepo: sl()),
  );
  // biblioteca local
  sl.registerLazySingleton<SavedVideosBaseLocalDataSource>(
    () => SavedVideosLocalDataSource(rootPath: DirHelper.getAppPath),
  );
  sl.registerLazySingleton<SavedVideosBaseRepo>(
    () => SavedVideosRepo(localDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetSavedVideosUseCase(repo: sl()));
  sl.registerLazySingleton(() => GetVideoThumbnailUseCase(repo: sl()));
  sl.registerLazySingleton(() => ProbeVideoDurationUseCase(repo: sl()));
  sl.registerLazySingleton(() => RecordSavedVideoUseCase(repo: sl()));
  sl.registerLazySingleton(() => ForgetSavedVideoUseCase(repo: sl()));
  sl.registerLazySingleton(
    () => LibraryCubit(
      getSavedVideos: sl(),
      getThumbnail: sl(),
      probeDuration: sl(),
      recordSavedVideo: sl(),
      forgetSavedVideo: sl(),
    ),
  );
  // downloader bloc
  sl.registerFactory(
    () => DownloaderBloc(
      getVideoUseCase: sl(),
      saveVideoUseCase: sl(),
      getFileSizeUseCase: sl(),
    ),
  );
}
