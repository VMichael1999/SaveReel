import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/helpers/dir_helper.dart';
import '../../../../../core/utils/app_enums.dart';
import '../../../domain/entities/cancel_signal.dart';
import '../../../domain/entities/download_item.dart';
import '../../../domain/entities/tiktok_video.dart';
import '../../../domain/usecases/get_file_size_usecase.dart';
import '../../../domain/usecases/get_video_usecase.dart';
import '../../../domain/usecases/save_video_usecase.dart';
import '../../models/download_format.dart';
import '../../models/video_player_args.dart';

part 'downloader_event.dart';

part 'downloader_state.dart';

class DownloaderBloc extends Bloc<DownloaderEvent, DownloaderState> {
  final GetVideoUseCase getVideoUseCase;
  final SaveVideoUseCase saveVideoUseCase;
  final GetFileSizeUseCase getFileSizeUseCase;

  DownloaderBloc({
    required this.getVideoUseCase,
    required this.saveVideoUseCase,
    required this.getFileSizeUseCase,
  }) : super(DownloaderInitial()) {
    on<DownloaderGetVideo>(_getVideo);
    on<DownloaderSaveVideo>(_saveVideo);
    on<DownloaderCancelVideo>(_cancelVideo);
    on<DownloaderRetryVideo>(_retryVideo);
    on<DownloaderDeleteVideo>(_deleteVideo);
  }

  /// Peso de un archivo en bytes, o nulo si no se pudo saber.
  Future<int?> fileSizeOf(String url) async {
    final result = await getFileSizeUseCase(url);
    return result.fold((_) => null, (size) => size);
  }

  List<DownloadItem> newDownloads = [];

  Future<void> _getVideo(
    DownloaderGetVideo event,
    Emitter<DownloaderState> emit,
  ) async {
    emit(const DownloaderGetVideoLoading());
    final result = await getVideoUseCase(event.videoLink);
    result.fold(
      (left) => emit(DownloaderGetVideoFailure(left.message)),
      (right) => emit(DownloaderGetVideoSuccess(right)),
    );
  }

  /// Señal de cancelación y formato de cada descarga, por ruta de archivo.
  final Map<String, CancelSignal> _signals = {};
  final Map<String, DownloadFormat> _formats = {};

  /// Rutas de las descargas cuya copia en la galería se pudo guardar.
  final Set<String> _inGallery = {};

  bool isInGallery(String path) => _inGallery.contains(path);

  /// Datos para abrir [path] en el reproductor, con título y autor si esta
  /// sesión sabe de quién es.
  VideoPlayerArgs playerArgsFor(String path) {
    final item = newDownloads.where((d) => d.path == path).firstOrNull;
    final data = item?.video.videoData;
    return VideoPlayerArgs(
      path: path,
      title: data?.title,
      authorHandle: data?.authorHandle,
      inGallery: isInGallery(path),
    );
  }

  /// Formato con que se pidió la descarga de [path], si sigue en la lista.
  DownloadFormat? formatOf(String path) => _formats[path];

  Future<void> _saveVideo(
    DownloaderSaveVideo event,
    Emitter<DownloaderState> emit,
  ) async {
    final videoData = event.tikTokVideo.videoData!;
    final format = event.format;
    final path = await _getPathFor(videoData.id, format);
    final link =
        format.isAudio
            ? format.urlOf(videoData)
            : _processLink(format.urlOf(videoData));

    final signal = CancelSignal();
    _signals[path] = signal;
    _formats[path] = format;
    _upsert(
      DownloadItem(
        video: event.tikTokVideo,
        status: DownloadStatus.downloading,
        path: path,
        startedAt: DateTime.now(),
      ),
    );
    emit(const DownloaderSaveVideoLoading());

    int lastPercent = -1;
    final params = SaveVideoParams(
      savePath: path,
      videoLink: link,
      cancelSignal: signal,
      onProgress: (received, total) {
        // Solo se emite cuando cambia el porcentaje, para no saturar la UI.
        final percent = total > 0 ? received * 100 ~/ total : received ~/ 65536;
        if (percent == lastPercent) return;
        lastPercent = percent;
        _update(
          path,
          (item) => item.copyWith(receivedBytes: received, totalBytes: total),
        );
        emit(
          DownloaderSaveVideoProgress(
            path: path,
            receivedBytes: received,
            totalBytes: total,
          ),
        );
      },
    );

    final result = await saveVideoUseCase(params);
    _signals.remove(path);
    final failure = result.fold((failure) => failure, (_) => null);
    if (failure is CancelRequestFailure) {
      await _discard(path);
      emit(DownloaderSaveVideoCancelled(path));
      return;
    }
    if (failure != null) {
      _update(
        path,
        (item) => item.copyWith(
          status: DownloadStatus.error,
          failureMessage: failure.message,
        ),
      );
      emit(DownloaderSaveVideoFailure(failure.message));
      return;
    }
    _update(
      path,
      (item) => item.copyWith(
        status: DownloadStatus.success,
        receivedBytes: item.totalBytes,
        clearFailure: true,
      ),
    );
    if (!format.isAudio && await _saveToGallery(path)) _inGallery.add(path);
    emit(
      DownloaderSaveVideoSuccess(
        message: result.fold((_) => '', (message) => message),
        path: path,
      ),
    );
  }

  void _cancelVideo(
    DownloaderCancelVideo event,
    Emitter<DownloaderState> emit,
  ) {
    _signals[event.path]?.cancel();
  }

  void _retryVideo(DownloaderRetryVideo event, Emitter<DownloaderState> emit) {
    final item = newDownloads.where((d) => d.path == event.path).firstOrNull;
    if (item == null) return;
    add(
      DownloaderSaveVideo(
        tikTokVideo: item.video,
        format: _formats[event.path] ?? DownloadFormat.withCredits,
      ),
    );
  }

  Future<void> _deleteVideo(
    DownloaderDeleteVideo event,
    Emitter<DownloaderState> emit,
  ) async {
    _inGallery.remove(event.path);
    await _discard(event.path);
    emit(DownloaderVideoDeleted(event.path));
  }

  /// Quita la descarga de la lista y borra lo que alcanzó a bajar.
  Future<void> _discard(String path) async {
    newDownloads.removeWhere((d) => d.path == path);
    _formats.remove(path);
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Copia el video a la galería. Si falla (por ejemplo, sin permiso),
  /// el archivo sigue disponible dentro de la app.
  Future<bool> _saveToGallery(String path) async {
    try {
      await DirHelper.saveVideoToGallery(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _processLink(String link) {
    bool isCorrectLink = link.endsWith(".mp4");
    if (!isCorrectLink) link += ".mp4";
    return link;
  }

  Future<String> _getPathFor(String id, DownloadFormat format) async {
    final appPath = await DirHelper.getAppPath();
    return "$appPath/${format.fileNameFor(id)}";
  }

  /// Agrega la descarga o, si ya existía (un reintento), la reemplaza.
  void _upsert(DownloadItem item) {
    final index = newDownloads.indexWhere((d) => d.path == item.path);
    if (index == -1) {
      newDownloads.add(item);
    } else {
      newDownloads[index] = item;
    }
  }

  void _update(String path, DownloadItem Function(DownloadItem) change) {
    final index = newDownloads.indexWhere((d) => d.path == path);
    if (index != -1) newDownloads[index] = change(newDownloads[index]);
  }
}
