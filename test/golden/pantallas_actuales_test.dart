import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/core/error/failure.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/cancel_signal.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/saved_video.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/tiktok_video.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/repositories/tiktok_video_base_repo.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_file_size_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/save_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/downloader_bloc/downloader_bloc.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/first_use_cubit/first_use_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/locale_cubit/locale_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/settings_cubit/settings_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/shared_link_cubit/shared_link_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/downloader_screen.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/library_screen.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/settings_screen.dart';

import '../support/fake_library.dart';

/// Capturas de las pantallas tal como están hoy en un iPhone normal, vertical
/// y horizontal. Los diseños del iPhone Duo no deben cambiarlas: si un golden
/// cambia fuera del Duo, es un error. Se regeneran solo a propósito, con
/// `flutter test --update-goldens test/golden`.

class _Repo implements TiktokVideoBaseRepo {
  @override
  Future<Either<Failure, TikTokVideo>> getVideo(String videoLink) async =>
      const Left(NotFoundFailure());

  @override
  Future<Either<Failure, int?>> getFileSize(String url) async =>
      const Right(null);

  @override
  Future<Either<Failure, String>> saveVideo({
    required String videoLink,
    required String savePath,
    void Function(int received, int total)? onProgress,
    CancelSignal? cancelSignal,
  }) async => const Right('ok');
}

const _sizes = <String, Size>{
  'vertical': Size(393, 852),
  'horizontal': Size(852, 393),
};

FakeSavedVideosRepo _repo() => FakeSavedVideosRepo(
  videos: [
    for (var i = 0; i < 8; i++)
      SavedVideo(
        path: '/app/video$i.mp4',
        sizeBytes: 5 * 1048576,
        modified: DateTime(2026, 1, 1).subtract(Duration(days: i)),
        title: 'Video $i',
        durationSeconds: 20 + i,
      ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  Size size,
  Widget Function() screen,
) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.hasStrings') {
      return <String, dynamic>{'value': false};
    }
    return null;
  });
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => Directory.systemTemp.path,
  );

  final repo = _Repo();
  final library = fakeLibraryCubit(_repo());
  await library.load();
  await tester.pumpWidget(
    BlocProvider(
      create:
          (_) => DownloaderBloc(
            getVideoUseCase: GetVideoUseCase(videoRepo: repo),
            saveVideoUseCase: SaveVideoUseCase(videoRepo: repo),
            getFileSizeUseCase: GetFileSizeUseCase(videoRepo: repo),
          ),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LibraryCubit>.value(value: library),
          BlocProvider<FirstUseCubit>.value(value: fakeFirstUseCubit()),
          BlocProvider<SharedLinkCubit>.value(value: fakeSharedLinkCubit()),
          BlocProvider<SettingsCubit>.value(value: fakeSettingsCubit()),
          BlocProvider<LocaleCubit>.value(value: fakeLocaleCubit()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: screen(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  final screens = <String, Widget Function()>{
    'inicio': () => const DownloaderScreen(),
    'biblioteca': () => const LibraryScreen(),
    'ajustes': () => const SettingsScreen(),
  };

  for (final screen in screens.entries) {
    for (final size in _sizes.entries) {
      testWidgets('${screen.key} ${size.key} igual a hoy', (tester) async {
        await _pump(tester, size.value, screen.value);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/${screen.key}_${size.key}.png'),
        );
      });
    }
  }
}
