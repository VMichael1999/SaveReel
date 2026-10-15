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
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/downloader_screen.dart';

import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/shared_link_cubit/shared_link_cubit.dart';
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

class _Screen {
  _Screen(this.store, this.opened);

  final MemoryOnboardingStore store;

  /// Veces que se pidió abrir TikTok.
  final List<int> opened;
}

Future<_Screen> _pump(
  WidgetTester tester, {
  bool dismissed = false,
  List<SavedVideo> library = const [],
  String? clipboardText,
  bool tikTokInstalled = true,
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
  final store = MemoryOnboardingStore(dismissed: dismissed);
  final firstUse = FirstUseCubit(store: store)..load();
  final libraryCubit = fakeLibraryCubit(FakeSavedVideosRepo(videos: library));
  await libraryCubit.load();
  final opened = <int>[];

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
        BlocProvider<LibraryCubit>.value(value: libraryCubit),
        BlocProvider<FirstUseCubit>.value(value: firstUse),
        BlocProvider<SharedLinkCubit>.value(value: fakeSharedLinkCubit()),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: DownloaderScreen(
          openTikTok: () async {
            opened.add(1);
            return tikTokInstalled;
          },
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return _Screen(store, opened);
}

SavedVideo _saved() => SavedVideo(
  path: '/app/a.mp4',
  sizeBytes: 1,
  modified: DateTime(2026, 1, 1),
  durationSeconds: 10,
);

void main() {
  testWidgets(
    'quien no ha guardado nada ve los tres pasos y las dos acciones',
    (tester) async {
      await _pump(tester);

      expect(find.text('Guarda cualquier video en 3 pasos'), findsOneWidget);
      expect(find.text('En TikTok o Instagram, toca Compartir'), findsOneWidget);
      expect(find.text('Elige «Copiar enlace»'), findsOneWidget);
      expect(find.text('Vuelve aquí'), findsOneWidget);
      expect(find.textContaining('álbum "SaveReel"'), findsOneWidget);
      expect(find.text('Abrir TikTok'), findsOneWidget);
      expect(find.text('Ya tengo un enlace'), findsOneWidget);
      // El campo del enlace todavía no aparece.
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets('no aparece si ya hay videos guardados', (tester) async {
    await _pump(tester, library: [_saved()]);

    expect(find.text('Guarda cualquier video en 3 pasos'), findsNothing);
    expect(find.text('Pega el enlace del video'), findsOneWidget);
  });

  testWidgets('no aparece si ya se descartó', (tester) async {
    await _pump(tester, dismissed: true);

    expect(find.text('Guarda cualquier video en 3 pasos'), findsNothing);
    expect(find.text('Pega el enlace del video'), findsOneWidget);
  });

  testWidgets('«Ya tengo un enlace» pasa al inicio y lo recuerda', (
    tester,
  ) async {
    final screen = await _pump(tester);

    await tester.tap(find.text('Ya tengo un enlace'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Guarda cualquier video en 3 pasos'), findsNothing);
    expect(find.text('Pega el enlace del video'), findsOneWidget);
    expect(await screen.store.isDismissed(), isTrue);
  });

  testWidgets('con un enlace de TikTok copiado se ofrece en vez de la guía', (
    tester,
  ) async {
    await _pump(tester, clipboardText: 'https://vm.tiktok.com/ZMh7K2pQx/');

    expect(find.text('Guarda cualquier video en 3 pasos'), findsNothing);
    expect(find.text('Tienes un enlace copiado'), findsOneWidget);
  });

  testWidgets('«Abrir TikTok» lo abre y, si no está, lo dice', (tester) async {
    final screen = await _pump(tester, tikTokInstalled: false);

    await tester.tap(find.text('Abrir TikTok'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(screen.opened, hasLength(1));
    expect(find.text('No encontramos TikTok en tu teléfono.'), findsOneWidget);
  });

  testWidgets(
    'tras el aviso de TikTok no instalado el otro botón sigue libre',
    (tester) async {
      final screen = await _pump(tester, tikTokInstalled: false);

      await tester.tap(find.text('Abrir TikTok'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('No encontramos TikTok en tu teléfono.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Ya tengo un enlace'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pega el enlace del video'), findsOneWidget);
      expect(await screen.store.isDismissed(), isTrue);
    },
  );

  testWidgets('si TikTok se abre no hay mensaje de error', (tester) async {
    final screen = await _pump(tester);

    await tester.tap(find.text('Abrir TikTok'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(screen.opened, hasLength(1));
    expect(find.text('No encontramos TikTok en tu teléfono.'), findsNothing);
  });

  testWidgets('cada paso se describe con su número para lectores de pantalla', (
    tester,
  ) async {
    await _pump(tester);

    expect(
      find.bySemanticsLabel('Paso 2: Elige «Copiar enlace»'),
      findsOneWidget,
    );
  });
}
