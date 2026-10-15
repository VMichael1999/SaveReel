import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/first_use_cubit/first_use_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/settings_cubit/settings_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/models/app_settings.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/models/download_format.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/shared_link_cubit/shared_link_cubit.dart';
import '../support/fake_library.dart';
import 'package:savetic/src/core/error/failure.dart';
import 'package:savetic/src/core/utils/video_link.dart';
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
  _FakeRepo({this.video = _video});

  /// Lo que devuelve la búsqueda del video.
  final TikTokVideo video;
  final List<String> saved = [];

  /// Enlaces de los que se pidió el peso al servidor de video.
  final List<String> sizeRequests = [];

  /// Pesos simulados por enlace, en bytes.
  final Map<String, int?> sizes = {
    'https://ejemplo.pe/con-marca': 9542041, // 9.1 MB
    'https://ejemplo.pe/limpio': 8808038, // 8.4 MB
    'https://ejemplo.pe/audio.mp3': 524288, // 0.5 MB
  };

  @override
  Future<Either<Failure, TikTokVideo>> getVideo(String videoLink) async =>
      Right(video);

  @override
  Future<Either<Failure, int?>> getFileSize(String url) async {
    sizeRequests.add(url);
    return Right(sizes[url]);
  }

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

Future<_FakeRepo> _openPreview(
  WidgetTester tester, {
  AppSettings settings = const AppSettings(),
  TikTokVideo video = _video,
}) async {
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

  final repo = _FakeRepo(video: video);
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
          BlocProvider<SettingsCubit>.value(value: fakeSettingsCubit(settings)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const DownloaderScreen(),
          onGenerateRoute:
              (_) => MaterialPageRoute(builder: (_) => const Scaffold()),
        ),
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

const _reel = TikTokVideo(
  code: 0,
  msg: 'success',
  processedTime: 0,
  videoData: VideoData(
    id: 'C9xQ2',
    duration: 0,
    title: 'Mi reel',
    originCover: 'https://ejemplo.pe/reel.jpg',
    playVideo: 'https://ejemplo.pe/reel.mp4?sig=abc&oe=1',
    wmPlayVideo: 'https://ejemplo.pe/reel.mp4?sig=abc&oe=1',
    music: '',
    playCount: 0,
    downloadCount: 0,
    authorHandle: 'viajes.peru',
    network: VideoNetwork.instagram,
  ),
);

void main() {
  testWidgets(
    'un video de Instagram ofrece un solo formato y sin cifras en 0',
    (tester) async {
      final repo = await _openPreview(tester, video: _reel);

      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Video con créditos'), findsNothing);
      expect(find.text('Solo el audio'), findsNothing);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.textContaining('reproducciones'), findsNothing);

      await tester.tap(find.textContaining('Descargar video'));
      await tester.pump();
      await _settle(tester);
      // La firma de la URL no se toca: no se le pega «.mp4» al final.
    expect(repo.saved, ['https://ejemplo.pe/reel.mp4?sig=abc&oe=1']);
      await drainToasts(tester);
    },
  );

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
      await drainToasts(tester);
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
    await drainToasts(tester);
  });

  testWidgets('el formato predeterminado de los ajustes viene elegido', (
    tester,
  ) async {
    await _openPreview(
      tester,
      settings: const AppSettings(defaultFormat: DownloadFormat.noWatermark),
    );

    expect(find.text('Descargar video · 8.4 MB'), findsOneWidget);
  });

  testWidgets('si el predeterminado es solo audio, el botón lo dice', (
    tester,
  ) async {
    await _openPreview(
      tester,
      settings: const AppSettings(defaultFormat: DownloadFormat.audio),
    );

    expect(find.text('Descargar audio · 0.5 MB'), findsOneWidget);
  });

  testWidgets(
    'usa los pesos que informa el servicio y solo pregunta por el resto',
    (tester) async {
      final repo = await _openPreview(
        tester,
        video: const TikTokVideo(
          code: 0,
          msg: 'success',
          processedTime: 0.5,
          videoData: VideoData(
            id: '42',
            duration: 218,
            title: 'La nieve de Mango',
            originCover: 'https://ejemplo.pe/portada.jpg',
            playVideo: 'https://ejemplo.pe/limpio',
            wmPlayVideo: 'https://ejemplo.pe/con-marca',
            music: 'https://ejemplo.pe/audio.mp3',
            playCount: 1,
            downloadCount: 1,
            playBytes: 79585360,
            wmPlayBytes: 65062252,
          ),
        ),
      );

      // 62.0 MB con créditos y 75.9 MB sin marca, sin preguntarle al servidor.
      expect(find.text('Descargar video · 62.0 MB'), findsOneWidget);
      expect(find.text('75.9 MB'), findsOneWidget);
      expect(find.text('0.5 MB'), findsOneWidget);
      expect(repo.sizeRequests, ['https://ejemplo.pe/audio.mp3']);
    },
  );
}
