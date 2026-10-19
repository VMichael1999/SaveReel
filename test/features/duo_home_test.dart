import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/core/error/failure.dart';
import 'package:savetic/src/core/layout/duo_layout.dart';
import 'package:savetic/src/core/layout/duo_side_bar.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/cancel_signal.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/tiktok_video.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/repositories/tiktok_video_base_repo.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_file_size_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/save_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/downloader_bloc/downloader_bloc.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/first_use_cubit/first_use_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/shared_link_cubit/shared_link_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/downloader_screen.dart';

import '../support/fake_library.dart';

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

Future<void> _pumpHome(WidgetTester tester, Size size) async {
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
          BlocProvider<LibraryCubit>.value(value: fakeLibraryCubit()),
          BlocProvider<FirstUseCubit>.value(value: fakeFirstUseCubit()),
          BlocProvider<SharedLinkCubit>.value(value: fakeSharedLinkCubit()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: const DownloaderScreen(),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('en el iPhone normal no hay franja y la barra sigue arriba', (
    tester,
  ) async {
    await _pumpHome(tester, const Size(393, 852));

    expect(find.byType(DuoSideBar), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('cerrado: Biblioteca y Ajustes pasan a la franja', (
    tester,
  ) async {
    await _pumpHome(tester, const Size(466, 678));

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(DuoSideBar), findsOneWidget);
    expect(find.byTooltip('Tus descargas'), findsOneWidget);
    expect(find.byTooltip('Ajustes'), findsOneWidget);
    expect(find.text('SaveReel'), findsOneWidget);
    expect(tester.getSize(find.byType(DuoSideBar)).width, kDuoSideBarWidth);
    expect(tester.getTopRight(find.byType(DuoSideBar)).dx, 466);
  });

  testWidgets('cerrado: golden del inicio', (tester) async {
    await _pumpHome(tester, const Size(466, 678));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/duo/inicio_cerrado.png'),
    );
  });
}
