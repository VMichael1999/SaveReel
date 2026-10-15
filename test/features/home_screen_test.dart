import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/first_use_cubit/first_use_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/shared_link_cubit/shared_link_cubit.dart';
import '../support/fake_library.dart';
import 'package:savetic/src/core/error/failure.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/cancel_signal.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/tiktok_video.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/repositories/tiktok_video_base_repo.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_file_size_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/save_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/downloader_bloc/downloader_bloc.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/downloader_screen.dart';

class _FakeRepo implements TiktokVideoBaseRepo {
  _FakeRepo({this.results = const [Left(NotFoundFailure())]});

  /// Respuestas de las búsquedas, una por intento; la última se repite.
  final List<Either<Failure, TikTokVideo>> results;
  int searches = 0;

  @override
  Future<Either<Failure, TikTokVideo>> getVideo(String videoLink) async =>
      results[(searches++).clamp(0, results.length - 1)];

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

void _mockPlatform({String? clipboardText}) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    switch (call.method) {
      case 'Clipboard.hasStrings':
        return <String, dynamic>{'value': clipboardText != null};
      case 'Clipboard.getData':
        return clipboardText == null
            ? null
            : <String, dynamic>{'text': clipboardText};
    }
    return null;
  });
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => Directory.systemTemp.path,
  );
}

Future<_FakeRepo> _pumpHome(
  WidgetTester tester, {
  List<Either<Failure, TikTokVideo>>? results,
}) async {
  final repo = results == null ? _FakeRepo() : _FakeRepo(results: results);
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
          theme: AppTheme.dark,
          home: const DownloaderScreen(),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  return repo;
}

// FilledButton.icon crea una subclase, así que byType no la encuentra.
final _filledButton = find.byWidgetPredicate((w) => w is FilledButton);

FilledButton _searchButton(WidgetTester tester) =>
    tester.widget<FilledButton>(_filledButton);

void main() {
  testWidgets('con un enlace de TikTok copiado lo ofrece y lo usa', (
    tester,
  ) async {
    _mockPlatform(
      clipboardText: 'Mira esto https://vm.tiktok.com/ZMh7K2pQx/ 🔥',
    );
    await _pumpHome(tester);

    expect(find.text('Tienes un enlace copiado'), findsOneWidget);
    expect(_searchButton(tester).onPressed, isNull);

    await tester.tap(find.text('Usar este enlace'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Tienes un enlace copiado'), findsNothing);
    expect(find.text('https://vm.tiktok.com/ZMh7K2pQx/'), findsOneWidget);
    expect(_searchButton(tester).onPressed, isNotNull);
  });

  testWidgets('sin enlace copiado no muestra la tarjeta', (tester) async {
    _mockPlatform();
    await _pumpHome(tester);

    expect(find.text('Tienes un enlace copiado'), findsNothing);
  });

  testWidgets('avisa cuando el enlace es de otra plataforma no compatible', (
    tester,
  ) async {
    _mockPlatform();
    await _pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'youtu.be/abc123');
    await tester.pump();

    expect(
      find.text(
        'Ese enlace es de YouTube, y por ahora solo bajamos de TikTok e Instagram.',
      ),
      findsOneWidget,
    );
    expect(_searchButton(tester).onPressed, isNull);
  });

  testWidgets('muestra el error del servicio dentro de la pantalla', (
    tester,
  ) async {
    _mockPlatform();
    await _pumpHome(tester);

    await tester.enterText(
      find.byType(TextField),
      'https://vm.tiktok.com/ZMh7K2pQx/',
    );
    await tester.pump();
    await tester.tap(_filledButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text(
        'No encontramos ese video. Puede ser privado o haber sido borrado.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('un video privado no ofrece reintentar', (tester) async {
    _mockPlatform();
    await _pumpHome(tester);

    await tester.enterText(
      find.byType(TextField),
      'https://vm.tiktok.com/ZMh7K2pQx/',
    );
    await tester.pump();
    await tester.tap(_filledButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('privado o haber sido borrado'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('si el servicio falla ofrece reintentar y vuelve a buscar', (
    tester,
  ) async {
    _mockPlatform();
    final repo = await _pumpHome(
      tester,
      results: const [
        Left(ServerFailure()),
        Left(NoInternetConnectionFailure()),
      ],
    );

    await tester.enterText(
      find.byType(TextField),
      'https://vm.tiktok.com/ZMh7K2pQx/',
    );
    await tester.pump();
    await tester.tap(_filledButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('El servicio tuvo un problema'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repo.searches, 2);
    expect(find.textContaining('Sin conexión'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('al escribir otro enlace desaparece el error y el reintento', (
    tester,
  ) async {
    _mockPlatform();
    await _pumpHome(tester, results: const [Left(ServerFailure())]);

    await tester.enterText(
      find.byType(TextField),
      'https://vm.tiktok.com/ZMh7K2pQx/',
    );
    await tester.pump();
    await tester.tap(_filledButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'https://vm.tiktok.com/ZMh7K2pQy/',
    );
    await tester.pump();

    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('al eliminar un video avisa «Video eliminado»', (tester) async {
    _mockPlatform();
    await _pumpHome(tester);

    final bloc =
        tester.element(find.byType(DownloaderScreen)).read<DownloaderBloc>();
    bloc.add(const DownloaderDeleteVideo('/app/video.mp4'));
    // Borrar usa E/S real de archivos; se alternan los dos relojes.
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    // El aviso se dibuja unos cuadros después de pedirlo.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Video eliminado'), findsOneWidget);
    await drainToasts(tester);
  });
}
