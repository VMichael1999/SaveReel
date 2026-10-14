import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import '../support/fake_library.dart';
import 'package:savetic/src/core/error/failure.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/cancel_signal.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/tiktok_video.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/video_data.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/repositories/tiktok_video_base_repo.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_file_size_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/save_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/downloader_bloc/downloader_bloc.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/downloads_screen.dart';

const _video = TikTokVideo(
  code: 0,
  msg: 'success',
  processedTime: 0.4,
  videoData: VideoData(
    id: '42',
    duration: 34,
    title: 'Ruta en bici por la Costa Verde',
    originCover: '',
    playVideo: 'https://ejemplo.pe/limpio',
    wmPlayVideo: 'https://ejemplo.pe/con-marca',
    music: 'https://ejemplo.pe/audio',
    playCount: 1,
    downloadCount: 1,
    authorHandle: 'rutas.lima',
  ),
);

class _Repo implements TiktokVideoBaseRepo {
  _Repo(this.onSave);

  final Future<Either<Failure, String>> Function(
    void Function(int, int)? onProgress,
    CancelSignal? signal,
  )
  onSave;

  @override
  Future<Either<Failure, TikTokVideo>> getVideo(String videoLink) async =>
      const Right(_video);

  @override
  Future<Either<Failure, int?>> getFileSize(String url) async =>
      const Right(null);

  @override
  Future<Either<Failure, String>> saveVideo({
    required String videoLink,
    required String savePath,
    void Function(int received, int total)? onProgress,
    CancelSignal? cancelSignal,
  }) => onSave(onProgress, cancelSignal);
}

/// La ruta de guardado mezcla un canal simulado con E/S real de archivos,
/// así que se alternan ambos relojes hasta que todo termine.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}

Future<DownloaderBloc> _pump(WidgetTester tester, _Repo repo) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final dir = await tester.runAsync(
    () => Directory.systemTemp.createTemp('sv'),
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => dir!.path,
      );

  // No se cierra el bloc al terminar: cerrarlo espera E/S real que el reloj
  // falso de la prueba ya no puede avanzar.
  final bloc = DownloaderBloc(
    getVideoUseCase: GetVideoUseCase(videoRepo: repo),
    saveVideoUseCase: SaveVideoUseCase(videoRepo: repo),
    getFileSizeUseCase: GetFileSizeUseCase(videoRepo: repo),
  );

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: bloc),
        BlocProvider<LibraryCubit>.value(value: fakeLibraryCubit()),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const DownloadsScreen(),
        onGenerateRoute:
            (_) => MaterialPageRoute(builder: (_) => const Scaffold()),
      ),
    ),
  );
  await _settle(tester);
  return bloc;
}

void main() {
  testWidgets('sin descargas explica qué pasa y ofrece una acción', (
    tester,
  ) async {
    await _pump(tester, _Repo((_, __) async => const Right('ok')));

    expect(find.text('Aún no has guardado nada'), findsOneWidget);
    expect(
      find.text('Cuando guardes un video, lo verás aquí.'),
      findsOneWidget,
    );
    expect(find.text('Pegar un enlace'), findsOneWidget);
  });

  testWidgets(
    'una descarga en curso muestra MB, porcentaje y se puede cancelar',
    (tester) async {
      final repo = _Repo((onProgress, signal) async {
        final cancelled = Completer<void>();
        signal!.onCancel(cancelled.complete);
        onProgress?.call(4928307, 7969177); // 4.7 de 7.6 MB
        await cancelled.future;
        return const Left(CancelRequestFailure());
      });
      final bloc = await _pump(tester, repo);

      bloc.add(const DownloaderSaveVideo(tikTokVideo: _video));
      await _settle(tester);

      expect(find.text('En curso'), findsOneWidget);
      expect(find.text('Ruta en bici por la Costa Verde'), findsOneWidget);
      expect(find.textContaining('4.7 de 7.6 MB · 61 %'), findsOneWidget);

      await tester.tap(find.byTooltip('Cancelar descarga'));
      await _settle(tester);

      expect(find.text('En curso'), findsNothing);
      expect(find.text('Aún no has guardado nada'), findsOneWidget);
    },
  );

  testWidgets('una descarga fallida dice qué pasó y deja reintentar', (
    tester,
  ) async {
    var attempt = 0;
    final repo = _Repo((onProgress, _) async {
      attempt++;
      if (attempt == 1) {
        onProgress?.call(34, 100);
        return const Left(NoInternetConnectionFailure());
      }
      return const Right('ok');
    });
    final bloc = await _pump(tester, repo);

    bloc.add(const DownloaderSaveVideo(tikTokVideo: _video));
    await _settle(tester);

    expect(
      find.text(const NoInternetConnectionFailure().message),
      findsOneWidget,
    );
    expect(
      find.textContaining('@rutas.lima · se quedó en 34 %'),
      findsOneWidget,
    );

    await tester.tap(find.text('Reintentar'));
    await _settle(tester);

    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('Ver video'), findsOneWidget);
    expect(find.textContaining('En tu galería'), findsOneWidget);
  });
}
