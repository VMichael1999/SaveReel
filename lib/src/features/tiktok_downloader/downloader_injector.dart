import 'domain/usecases/set_favorite_usecase.dart';
import '../../core/helpers/language_store.dart';
import 'presentation/bloc/locale_cubit/locale_cubit.dart';
import 'package:dio/dio.dart';

import '../../container_injector.dart';
import '../../core/helpers/background_downloads.dart';
import '../../core/helpers/dir_helper.dart';
import '../../core/helpers/onboarding_store.dart';
import '../../core/helpers/settings_store.dart';
import '../../core/helpers/shared_link_receiver.dart';
import '../../core/utils/app_constants.dart';
import 'data/datasources/local/saved_videos_local_data_source.dart';
import 'data/datasources/remote/tiktok_video_remote_data_source.dart';
import 'data/repositories/saved_videos_repo.dart';
import 'data/repositories/tiktok_video_repo.dart';
import 'data/sources/instagram_cobalt_client.dart';
import 'data/sources/instagram_video_source.dart';
import 'domain/repositories/saved_videos_base_repo.dart';
import 'domain/repositories/tiktok_video_base_repo.dart';
import 'domain/usecases/clear_thumbnail_cache_usecase.dart';
import 'domain/usecases/forget_saved_video_usecase.dart';
import 'domain/usecases/get_saved_videos_usecase.dart';
import 'domain/usecases/get_thumbnail_cache_size_usecase.dart';
import 'domain/usecases/get_video_thumbnail_usecase.dart';
import 'domain/usecases/probe_video_duration_usecase.dart';
import 'domain/usecases/record_saved_video_usecase.dart';
import 'presentation/bloc/first_use_cubit/first_use_cubit.dart';
import 'presentation/bloc/library_cubit/library_cubit.dart';
import 'presentation/bloc/settings_cubit/settings_cubit.dart';
import 'presentation/bloc/shared_link_cubit/shared_link_cubit.dart';
import 'domain/usecases/get_file_size_usecase.dart';
import 'domain/usecases/get_video_usecase.dart';
import 'domain/usecases/save_video_usecase.dart';
import 'presentation/bloc/downloader_bloc/downloader_bloc.dart';

void initDownloader() {
  // data source
  sl.registerLazySingleton<TiktokVideoBaseRemoteDataSource>(
    () => TiktokVideoRemoteDataSource(dioHelper: sl()),
  );
  // Instagram: cliente propio, sin las cabeceras del servicio de TikTok
  sl.registerLazySingleton(
    () => InstagramVideoSource(
      dio: Dio(),
      cobalt: InstagramCobaltClient(
        dio: Dio(),
        baseUrl: AppConstants.cobaltUrl,
        apiKey: AppConstants.cobaltKey,
      ),
    ),
  );
  // repository
  sl.registerLazySingleton<TiktokVideoBaseRepo>(
    () => TiktokVideoRepo(remoteDataSource: sl(), instagramSource: sl()),
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
  sl.registerLazySingleton(() => SetFavoriteUseCase(repo: sl()));
  sl.registerLazySingleton(() => GetThumbnailCacheSizeUseCase(repo: sl()));
  sl.registerLazySingleton(() => ClearThumbnailCacheUseCase(repo: sl()));
  sl.registerLazySingleton(
    () => LibraryCubit(
      getSavedVideos: sl(),
      getThumbnail: sl(),
      probeDuration: sl(),
      recordSavedVideo: sl(),
      forgetSavedVideo: sl(),
      setFavoriteUseCase: sl(),
      getThumbnailCacheSize: sl(),
      clearThumbnailCacheUseCase: sl(),
    ),
  );
  // enlaces que llegan desde «Compartir»
  sl.registerLazySingleton(() => SharedLinkReceiver());
  sl.registerLazySingleton(() => SharedLinkCubit(receiver: sl()));
  // ajustes
  sl.registerLazySingleton(() => SettingsStore());
  sl.registerLazySingleton(() => SettingsCubit(store: sl()));
  // primer uso
  sl.registerLazySingleton(() => LanguageStore());
  sl.registerLazySingleton(() => LocaleCubit(store: sl()));

  sl.registerLazySingleton(() => OnboardingStore());
  sl.registerLazySingleton(() => FirstUseCubit(store: sl()));
  // downloader bloc
  sl.registerFactory(
    () => DownloaderBloc(
      getVideoUseCase: sl(),
      saveVideoUseCase: sl(),
      getFileSizeUseCase: sl(),
      shouldSaveToGallery: () => sl<SettingsCubit>().state.saveToGallery,
      background: const PlatformBackgroundDownloads(),
    ),
  );
}
