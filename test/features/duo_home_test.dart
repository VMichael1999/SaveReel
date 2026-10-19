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
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/duo_pane_cubit/duo_pane_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/settings_cubit/settings_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/models/download_format.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/widgets/video_preview/video_preview_sheet.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/video_data.dart';
import 'package:savetic/src/core/layout/duo_split.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/downloader_screen.dart';

import '../support/fake_library.dart';

class _Repo implements TiktokVideoBaseRepo {
  _Repo({this.finds = false});

  /// Si la búsqueda encuentra el video de prueba.
  final bool finds;

  @override
  Future<Either<Failure, TikTokVideo>> getVideo(String videoLink) async =>
      finds ? const Right(_video) : const Left(NotFoundFailure());

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

Future<void> _pumpHome(
  WidgetTester tester,
  Size size, {
  DuoPaneCubit? pane,
  bool keepSize = false,
  bool finds = false,
}) async {
  if (!keepSize) {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

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

  final repo = _Repo(finds: finds);
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
          BlocProvider<SettingsCubit>.value(value: fakeSettingsCubit()),
          BlocProvider<DuoPaneCubit>.value(value: pane ?? DuoPaneCubit()),
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

  group('abierto en horizontal', () {
    const open = Size(951, 669);

    test('el reparto deja el centro de toda la pantalla entre las mitades', () {
      final halves = duoHalves(951, 84);

      expect(halves.left, 951 / 2 - kDuoFoldGap);
      // La derecha empieza en el centro + 12 y acaba donde empieza la franja.
      expect(951 - 84 - halves.right, 951 / 2 + kDuoFoldGap);
      expect(halves.right, lessThan(halves.left));
    });

    testWidgets('sin nada que mostrar, el inicio ocupa la izquierda', (
      tester,
    ) async {
      await _pumpHome(tester, open);

      expect(find.byType(DuoSideBar), findsOneWidget);
      expect(find.byType(VideoPreviewPanel), findsNothing);
      expect(find.text('Pega el enlace del video'), findsOneWidget);
      expect(
        tester.getTopRight(find.text('Pega el enlace del video')).dx,
        lessThan(951 / 2),
      );
    });

    testWidgets('la vista previa aparece a la derecha, sin hoja', (
      tester,
    ) async {
      final pane = DuoPaneCubit();
      await _pumpHome(tester, open, pane: pane);

      pane.showPreview(_video);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(VideoPreviewPanel), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        tester.getTopLeft(find.byType(VideoPreviewPanel)).dx,
        greaterThanOrEqualTo(951 / 2 + kDuoFoldGap),
      );
      expect(find.text('Ruta en bici por la Costa Verde'), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/duo/inicio_y_vista_previa_abierto.png'),
      );
    });

    testWidgets('las descargas se muestran a la derecha', (tester) async {
      final pane = DuoPaneCubit();
      await _pumpHome(tester, open, pane: pane);

      pane.showDownloads();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Descargas'), findsOneWidget);
    });

    testWidgets('al cerrar el teléfono la vista previa vuelve a ser la hoja '
        'con el mismo formato', (tester) async {
      final pane = DuoPaneCubit();
      await _pumpHome(tester, open, pane: pane);
      pane.showPreview(_video, DownloadFormat.noWatermark);
      await tester.pump(const Duration(milliseconds: 300));

      tester.view.physicalSize = const Size(466, 678) * 3;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(VideoPreviewSheet), findsOneWidget);
      expect(pane.state.isNone, isTrue);
      final panel = tester.widget<VideoPreviewPanel>(
        find.byType(VideoPreviewPanel),
      );
      expect(panel.initialFormat, DownloadFormat.noWatermark);
    });

    testWidgets('al abrir el teléfono la hoja pasa a la mitad derecha', (
      tester,
    ) async {
      final pane = DuoPaneCubit();
      await _pumpHome(tester, const Size(466, 678), pane: pane, finds: true);
      await tester.enterText(
        find.byType(TextField),
        'https://vm.tiktok.com/ZMh7K2pQx/',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Buscar video'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      tester.view.physicalSize = open * 3;
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(VideoPreviewPanel), findsOneWidget);
      expect(pane.state.video, isNotNull);
      // El enlace escrito sigue en el campo.
      expect(find.text('https://vm.tiktok.com/ZMh7K2pQx/'), findsOneWidget);
    });
  });
}
