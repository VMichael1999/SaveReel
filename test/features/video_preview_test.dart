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
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/downloader_screen.dart';

const _video = TikTokVideo(
  code: 0,
  msg: 'success',
  processedTime: 0.4,
  videoData: VideoData(
    id: '42',
    duration: 34,
    title: 'Lomo saltado en 10 minutos, versión fácil',
    originCover: 'https://ejemplo.pe/portada.jpg',
    playVideo: 'https://ejemplo.pe/limpio',
    wmPlayVideo: 'https://ejemplo.pe/con-marca',
    music: 'https://ejemplo.pe/audio.mp3',
    playCount: 1200000,
    downloadCount: 18600,
    authorHandle: 'cocinaconlucia',
  ),
);

class _FakeRepo implements TiktokVideoBaseRepo {
  final List<String> saved = [];

  /// Pesos simulados por enlace, en bytes.
  final Map<String, int?> sizes = {
    'https://ejemplo.pe/con-marca': 9542041, // 9.1 MB
    'https://ejemplo.pe/limpio': 8808038, // 8.4 MB
    'https://ejemplo.pe/audio.mp3': 524288, // 0.5 MB
  };

  @override
  Future<Either<Failure, TikTokVideo>> getVideo(String videoLink) async =>
      const Right(_video);

  @override
  Future<Either<Failure, int?>> getFileSize(String url) async =>
      Right(sizes[url]);

  @override
  Future<Either<Failure, String>> saveVideo({
    required String videoLink,
    required String savePath,
    void Function(int received, int total)? onProgress,
    CancelSignal? cancelSignal,
  }) async {
    saved.add(videoLink);
    return const Right('ok');
  }
}

Future<_FakeRepo> _openPreview(WidgetTester tester) async {
  // Pantalla de teléfono: con la de prueba por defecto el botón queda fuera.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.hasStrings') return {'value': false};
    return null;
  });
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => Directory.systemTemp.path,
  );

  final repo = _FakeRepo();
  await tester.pumpWidget(
    BlocProvider(
      create:
          (_) => DownloaderBloc(
            getVideoUseCase: GetVideoUseCase(videoRepo: repo),
            saveVideoUseCase: SaveVideoUseCase(videoRepo: repo),
            getFileSizeUseCase: GetFileSizeUseCase(videoRepo: repo),
          ),
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const DownloaderScreen(),
        onGenerateRoute:
            (_) => MaterialPageRoute(builder: (_) => const Scaffold()),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.enterText(
    find.byType(TextField),
    'https://vm.tiktok.com/ZMh7K2pQx/',
  );
  await tester.pump();
  await tester.tap(find.byWidgetPredicate((w) => w is FilledButton));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  // Los pesos llegan después de que la hoja se abre.
  await tester.pump();
  return repo;
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

void main() {
  testWidgets('la vista previa muestra autor, duración y cifras con etiqueta', (
    tester,
  ) async {
    await _openPreview(tester);

    expect(
      find.text('Lomo saltado en 10 minutos, versión fácil'),
      findsOneWidget,
    );
    expect(find.text('@cocinaconlucia'), findsOneWidget);
    expect(find.textContaining('0:34'), findsOneWidget);
    expect(find.textContaining('1.2 M'), findsOneWidget);
    expect(find.textContaining('18.6 K'), findsOneWidget);
    expect(
      find.text('Si lo compartes, menciona a @cocinaconlucia.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'el video con créditos viene elegido y se descarga con su enlace',
    (tester) async {
      final repo = await _openPreview(tester);

      expect(find.text('Descargar video · 9.1 MB'), findsOneWidget);
      await tester.tap(find.text('Descargar video · 9.1 MB'));
      await tester.pump();
      await _settle(tester);

      expect(repo.saved, ['https://ejemplo.pe/con-marca.mp4']);
    },
  );

  testWidgets('al elegir solo el audio cambia el botón y el enlace', (
    tester,
  ) async {
    final repo = await _openPreview(tester);

    await tester.tap(find.text('Solo el audio'));
    await tester.pump();

    expect(find.text('Descargar audio · 0.5 MB'), findsOneWidget);
    await tester.tap(find.text('Descargar audio · 0.5 MB'));
    await tester.pump();
    await _settle(tester);

    expect(repo.saved, ['https://ejemplo.pe/audio.mp3']);
  });
}
