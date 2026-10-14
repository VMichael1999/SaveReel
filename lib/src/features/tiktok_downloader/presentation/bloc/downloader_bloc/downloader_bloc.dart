import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../../../core/helpers/dir_helper.dart';
import '../../../../../core/utils/app_enums.dart';
import '../../../domain/entities/download_item.dart';
import '../../../domain/entities/tiktok_video.dart';
import '../../../domain/entities/video_item.dart';
import '../../../domain/usecases/get_file_size_usecase.dart';
import '../../../domain/usecases/get_video_usecase.dart';
import '../../../domain/usecases/save_video_usecase.dart';
import '../../models/download_format.dart';

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
    on<LoadOldDownloads>(_loadOldDownloads);
    on<DownloaderGetVideo>(_getVideo);
    on<DownloaderSaveVideo>(_saveVideo);
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

  Future<void> _saveVideo(
    DownloaderSaveVideo event,
    Emitter<DownloaderState> emit,
  ) async {
    final videoData = event.tikTokVideo.videoData!;
    final format = event.format;
    final path = await _getPathFor(videoData.id, format);
    final link = format.isAudio
        ? format.urlOf(videoData)
        : _processLink(format.urlOf(videoData));
    DownloadItem item = DownloadItem(
      video: event.tikTokVideo,
      status: DownloadStatus.downloading,
      path: path,
    );
    int index = _checkIfItemIsExistInDownloads(item);
    _addItem(index, item);
    emit(const DownloaderSaveVideoLoading());

    int lastPercent = -1;
    final params = SaveVideoParams(
      savePath: path,
      videoLink: link,
      onProgress: (received, total) {
        // Solo se emite cuando cambia el porcentaje, para no saturar la UI.
        final percent = total > 0 ? received * 100 ~/ total : received ~/ 65536;
        if (percent == lastPercent) return;
        lastPercent = percent;
        _updateItem(
          index,
          item.copyWith(receivedBytes: received, totalBytes: total),
        );
        emit(DownloaderSaveVideoProgress(
          path: path,
          receivedBytes: received,
          totalBytes: total,
        ));
      },
    );

    final result = await saveVideoUseCase(params);
    final failure = result.fold((failure) => failure, (_) => null);
    if (failure != null) {
      _updateItem(index, item.copyWith(status: DownloadStatus.error));
      emit(DownloaderSaveVideoFailure(failure.message));
      return;
    }
    _updateItem(index, item.copyWith(status: DownloadStatus.success));
    if (!format.isAudio) await _saveToGallery(path);
    emit(DownloaderSaveVideoSuccess(
      message: result.fold((_) => '', (message) => message),
      path: path,
    ));
  }

  /// Copia el video a la galería. Si falla (por ejemplo, sin permiso),
  /// el archivo sigue disponible dentro de la app.
  Future<void> _saveToGallery(String path) async {
    try {
      await DirHelper.saveVideoToGallery(path);
    } catch (_) {}
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

  _updateItem(int index, DownloadItem item) {
    if (index == -1) {
      newDownloads.last = item;
    } else {
      newDownloads[index] = item;
    }
  }

  _addItem(int index, DownloadItem item) {
    if (index == -1) {
      newDownloads.add(item);
    } else {
      newDownloads[index] = item.copyWith(status: DownloadStatus.downloading);
    }
  }

  int _checkIfItemIsExistInDownloads(DownloadItem item) {
    int index = -1;
    for (int i = 0; i < newDownloads.length; i++) {
      if (newDownloads[i].video == item.video) {
        index = i;
        return index;
      }
    }
    return index;
  }

  List<VideoItem> oldDownloads = [];

  Future<void> _loadOldDownloads(
    LoadOldDownloads event,
    Emitter<DownloaderState> emit,
  ) async {
    emit(const OldDownloadsLoading());
    oldDownloads.clear();
    final path = await DirHelper.getAppPath();
    final directory = Directory(path);
    final files = await directory.list().toList();
    final newDownloadedVideosPaths = newDownloads.map((e) => e.path);
    for (final file in files) {
      if (file is File && file.path.endsWith('.mp4')) {
        final videoPath = file.path;
        if (newDownloadedVideosPaths.contains(videoPath)) continue;
        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.PNG,
          quality: 30,
        );
        oldDownloads
            .add(VideoItem(path: videoPath)..thumbnailPath = thumbnailPath);
      }
    }
    emit(OldDownloadsLoadingSuccess(downloads: oldDownloads));
  }
}
