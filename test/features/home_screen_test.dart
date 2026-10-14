import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/core/error/failure.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/tiktok_video.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/repositories/tiktok_video_base_repo.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/save_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/downloader_bloc/downloader_bloc.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/screens/downloader_screen.dart';

class _FakeRepo implements TiktokVideoBaseRepo {
  @override
  Future<Either<Failure, TikTokVideo>> getVideo(String videoLink) async =>
      const Left(NotFoundFailure());

  @override
  Future<Either<Failure, String>> saveVideo({
    required String videoLink,
    required String savePath,
    void Function(int received, int total)? onProgress,
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

Future<void> _pumpHome(WidgetTester tester) async {
  final repo = _FakeRepo();
  await tester.pumpWidget(
    BlocProvider(
      create:
          (_) => DownloaderBloc(
            getVideoUseCase: GetVideoUseCase(videoRepo: repo),
            saveVideoUseCase: SaveVideoUseCase(videoRepo: repo),
          ),
      child: MaterialApp(theme: AppTheme.dark, home: const DownloaderScreen()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
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

  testWidgets('avisa cuando el enlace es de otra plataforma', (tester) async {
    _mockPlatform();
    await _pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'instagram.com/reel/C9xQ2');
    await tester.pump();

    expect(
      find.text('Ese enlace es de Instagram, no de TikTok.'),
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
}
