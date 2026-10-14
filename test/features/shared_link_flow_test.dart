import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/core/error/failure.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/cancel_signal.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/tiktok_video.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/video_data.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/repositories/tiktok_video_base_repo.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_file_size_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/save_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/downloader_bloc/downloader_bloc.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/first_use_cubit/first_use_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/settings_cubit/settings_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/shared_link_cubit/shared_link_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/downloader_screen.dart';

import '../support/fake_library.dart';

const _video = TikTokVideo(
  code: 0,
  msg: 'success',
  processedTime: 0.4,
  videoData: VideoData(
    id: '42',
    duration: 218,
    title: 'La nieve de Mango Parte 1.2.3',
    originCover: '',
    playVideo: 'https://ejemplo.pe/limpio',
    wmPlayVideo: 'https://ejemplo.pe/con-marca',
    music: 'https://ejemplo.pe/audio.mp3',
    playCount: 2225973,
    downloadCount: 487,
    authorHandle: 'frutinoveladrama9',
  ),
);

class _Repo implements TiktokVideoBaseRepo {
  /// Enlaces que se le pidieron al servicio.
  final List<String> searched = [];

  @override
  Future<Either<Failure, TikTokVideo>> getVideo(String videoLink) async {
    searched.add(videoLink);
    return const Right(_video);
  }

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

Future<(_Repo, FakeSharedSource)> _pump(
  WidgetTester tester, {
  String? initialShared,
  bool firstUseDismissed = false,
  String? clipboardText,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    switch (call.method) {
      case 'Clipboard.hasStrings':
        return {'value': clipboardText != null};
      case 'Clipboard.getData':
        return clipboardText == null ? null : {'text': clipboardText};
    }
    return null;
  });
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => Directory.systemTemp.path,
  );

  final repo = _Repo();
  final source = FakeSharedSource(initial: initialShared);
  final shared = fakeSharedLinkCubit(source);
  await tester.runAsync(shared.start);
  final library = fakeLibraryCubit();
  await tester.runAsync(library.load);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (_) => DownloaderBloc(
                getVideoUseCase: GetVideoUseCase(videoRepo: repo),
                saveVideoUseCase: SaveVideoUseCase(videoRepo: repo),
                getFileSizeUseCase: GetFileSizeUseCase(videoRepo: repo),
              ),
        ),
        BlocProvider<LibraryCubit>.value(value: library),
        BlocProvider<FirstUseCubit>.value(
          value: fakeFirstUseCubit(dismissed: firstUseDismissed),
        ),
        BlocProvider<SettingsCubit>.value(value: fakeSettingsCubit()),
        BlocProvider<SharedLinkCubit>.value(value: shared),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const DownloaderScreen(),
        onGenerateRoute:
            (_) => MaterialPageRoute(builder: (_) => const Scaffold()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  return (repo, source);
}

void main() {
  testWidgets(
    'abrir la app desde «Compartir» pone el enlace, busca el video y ofrece los formatos',
    (tester) async {
      final (repo, _) = await _pump(
        tester,
        initialShared:
            'Mira esto https://www.tiktok.com/@frutinoveladrama9/video/7689496424051952910?is_from_webapp=1&sender_device=pc',
      );

      // El enlace se buscó limpio, sin los parámetros de seguimiento.
      expect(repo.searched, [
        'https://www.tiktok.com/@frutinoveladrama9/video/7689496424051952910',
      ]);
      expect(find.text('La nieve de Mango Parte 1.2.3'), findsOneWidget);
      expect(find.text('@frutinoveladrama9'), findsOneWidget);
      expect(find.text('Video con créditos'), findsOneWidget);
      expect(find.text('Video sin marca de agua'), findsOneWidget);
      expect(find.text('Solo el audio'), findsOneWidget);
    },
  );

  testWidgets('también funciona con la app ya abierta', (tester) async {
    final (repo, source) = await _pump(tester, firstUseDismissed: true);
    expect(repo.searched, isEmpty);

    source.controller.add('ve esto https://vm.tiktok.com/ZMh7K2pQx/');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(repo.searched, ['https://vm.tiktok.com/ZMh7K2pQx/']);
    expect(find.text('Video con créditos'), findsOneWidget);
  });

  testWidgets(
    'quien nunca guardó nada ve el inicio, no la guía, al compartir',
    (tester) async {
      await _pump(
        tester,
        initialShared: 'https://vm.tiktok.com/ZMh7K2pQx/',
        firstUseDismissed: false,
      );

      expect(find.text('Guarda cualquier video en 3 pasos'), findsNothing);
      expect(find.text('Video con créditos'), findsOneWidget);
    },
  );

  testWidgets('el texto que no trae un enlace de TikTok no busca nada', (
    tester,
  ) async {
    final (repo, source) = await _pump(tester, firstUseDismissed: true);

    source.controller.add('hola, esto no es un enlace');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(repo.searched, isEmpty);
    expect(find.text('Video con créditos'), findsNothing);
  });

  testWidgets(
    'si el enlace compartido es el mismo del portapapeles no repite la tarjeta',
    (tester) async {
      await _pump(
        tester,
        initialShared:
            'https://www.tiktok.com/@frutinoveladrama9/video/7689496424051952910',
        clipboardText:
            'https://www.tiktok.com/@frutinoveladrama9/video/7689496424051952910?is_from_webapp=1&sender_device=pc',
      );

      expect(find.text('Video con créditos'), findsOneWidget);
      expect(find.text('Tienes un enlace copiado'), findsNothing);
    },
  );
}
