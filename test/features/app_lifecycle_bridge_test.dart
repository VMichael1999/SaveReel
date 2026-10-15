import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/error/failure.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/cancel_signal.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/tiktok_video.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/repositories/tiktok_video_base_repo.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_file_size_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/get_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/usecases/save_video_usecase.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/downloader_bloc/downloader_bloc.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/widgets/app_lifecycle_bridge.dart';

class _NoRepo implements TiktokVideoBaseRepo {
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

/// Un bloc que anota los avisos de ciclo de vida que recibe.
class _SpyBloc extends DownloaderBloc {
  _SpyBloc(_NoRepo repo)
    : super(
        getVideoUseCase: GetVideoUseCase(videoRepo: repo),
        saveVideoUseCase: SaveVideoUseCase(videoRepo: repo),
        getFileSizeUseCase: GetFileSizeUseCase(videoRepo: repo),
      );

  final List<bool> away = [];

  @override
  void add(DownloaderEvent event) {
    if (event is DownloaderAppLifecycleChanged) away.add(event.away);
    super.add(event);
  }
}

void main() {
  testWidgets('avisa al bloc cuando la app se va y cuando vuelve', (
    tester,
  ) async {
    final bloc = _SpyBloc(_NoRepo());
    await tester.pumpWidget(
      BlocProvider<DownloaderBloc>.value(
        value: bloc,
        child: const MaterialApp(
          home: AppLifecycleBridge(child: Scaffold(body: Text('hola'))),
        ),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(bloc.away.first, isTrue);
    expect(bloc.away.last, isFalse);
    expect(bloc.away, contains(true));
    // No se cierra el bloc: cerrarlo dentro de una prueba de widgets la cuelga.
  });
}
