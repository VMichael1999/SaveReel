import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/error/failure.dart';
import 'package:flutter/widgets.dart';
import 'package:savetic/src/core/helpers/language_store.dart';
import 'package:savetic/src/core/helpers/onboarding_store.dart';
import 'package:savetic/src/core/helpers/settings_store.dart';
import 'package:savetic/src/core/helpers/shared_link_receiver.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/saved_video.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/repositories/saved_videos_base_repo.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/clear_thumbnail_cache_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/forget_saved_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_saved_videos_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_thumbnail_cache_size_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_video_thumbnail_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/probe_video_duration_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/record_saved_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/first_use_cubit/first_use_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/locale_cubit/locale_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/settings_cubit/settings_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/shared_link_cubit/shared_link_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/models/app_settings.dart';

/// Biblioteca en memoria para las pruebas.
class FakeSavedVideosRepo implements SavedVideosBaseRepo {
  FakeSavedVideosRepo({
    List<SavedVideo> videos = const [],
    Map<String, int?> durations = const {},
  }) : videos = [...videos],
       durations = {...durations};

  final List<SavedVideo> videos;

  /// Duración que "leería" del archivo, por ruta.
  final Map<String, int?> durations;
  final List<SavedVideoMetadata> recorded = [];
  final List<String> forgotten = [];

  @override
  Future<Either<Failure, List<SavedVideo>>> list() async => Right([...videos]);

  @override
  Future<Either<Failure, String?>> thumbnailFor(String path) async =>
      const Right(null);

  @override
  Future<Either<Failure, int?>> probeDuration(String path) async =>
      Right(durations[path]);

  @override
  Future<Either<Failure, Unit>> record(SavedVideoMetadata metadata) async {
    recorded.add(metadata);
    videos.insert(
      0,
      SavedVideo(
        path: metadata.path,
        sizeBytes: 1,
        modified: DateTime.now(),
        title: metadata.title,
        authorHandle: metadata.authorHandle,
        durationSeconds: metadata.durationSeconds,
        network: metadata.network,
      ),
    );
    return const Right(unit);
  }

  /// Peso simulado de las portadas en caché.
  int cacheBytes = 0;
  int cacheClears = 0;

  @override
  Future<Either<Failure, int>> thumbnailCacheSize() async => Right(cacheBytes);

  @override
  Future<Either<Failure, Unit>> clearThumbnailCache() async {
    cacheClears++;
    cacheBytes = 0;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> forget(String path) async {
    forgotten.add(path);
    return const Right(unit);
  }
}

LibraryCubit fakeLibraryCubit([FakeSavedVideosRepo? repo]) {
  final r = repo ?? FakeSavedVideosRepo();
  return LibraryCubit(
    getSavedVideos: GetSavedVideosUseCase(repo: r),
    getThumbnail: GetVideoThumbnailUseCase(repo: r),
    probeDuration: ProbeVideoDurationUseCase(repo: r),
    recordSavedVideo: RecordSavedVideoUseCase(repo: r),
    forgetSavedVideo: ForgetSavedVideoUseCase(repo: r),
    getThumbnailCacheSize: GetThumbnailCacheSizeUseCase(repo: r),
    clearThumbnailCacheUseCase: ClearThumbnailCacheUseCase(repo: r),
  );
}

/// Almacén de la guía de primer uso que vive solo en memoria.
class MemoryOnboardingStore extends OnboardingStore {
  MemoryOnboardingStore({bool dismissed = false}) : _dismissed = dismissed;

  bool _dismissed;

  @override
  Future<bool> isDismissed() async => _dismissed;

  @override
  Future<void> dismiss() async => _dismissed = true;
}

/// Por omisión la guía ya está descartada, para no estorbar otras pruebas.
FirstUseCubit fakeFirstUseCubit({bool dismissed = true}) =>
    FirstUseCubit(store: MemoryOnboardingStore(dismissed: dismissed))..load();

/// Almacén de ajustes en memoria.
class MemorySettingsStore extends SettingsStore {
  MemorySettingsStore([Map<String, dynamic>? initial]) : saved = {...?initial};

  Map<String, dynamic> saved;

  @override
  Future<Map<String, dynamic>> read() async => {...saved};

  @override
  Future<void> write(Map<String, dynamic> values) async => saved = {...values};
}

/// Ajustes ya cargados, por omisión los de fábrica.
SettingsCubit fakeSettingsCubit([AppSettings settings = const AppSettings()]) =>
    SettingsCubit(store: MemorySettingsStore(settings.toJson()))..load();

/// Almacén del idioma en memoria.
class MemoryLanguageStore extends LanguageStore {
  MemoryLanguageStore([this.saved]);

  String? saved;

  @override
  Future<String?> read() async => saved;

  @override
  Future<void> write(String code) async => saved = code;
}

/// Idioma ya cargado: español salvo que se pida otro.
LocaleCubit fakeLocaleCubit([String? code]) => LocaleCubit(
  store: MemoryLanguageStore(code),
  deviceLocale: () => const Locale('es'),
)..load();

/// Fuente de texto compartido que las pruebas controlan a mano.
class FakeSharedSource implements SharedTextSource, MissingLinkSource {
  FakeSharedSource({this.initial, this.missingAtStart = false});

  final String? initial;

  /// Simula abrir la app con el atajo «guardar el enlace copiado» sin enlace.
  final bool missingAtStart;
  final StreamController<String> controller = StreamController.broadcast();
  final StreamController<void> missingController = StreamController.broadcast();

  @override
  Future<String?> initialText() async {
    if (missingAtStart) missingController.add(null);
    return initial;
  }

  @override
  Stream<void> get missing => missingController.stream;

  @override
  Stream<String> get texts => controller.stream;
}

SharedLinkCubit fakeSharedLinkCubit([FakeSharedSource? source]) =>
    SharedLinkCubit(
      receiver: SharedLinkReceiver(sources: [source ?? FakeSharedSource()]),
    );

/// Deja pasar el tiempo que un aviso tarda en cerrarse solo. Una prueba que
/// termina con un aviso en pantalla deja su temporizador pendiente y falla.
Future<void> drainToasts(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 7));
