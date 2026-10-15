part of 'downloader_bloc.dart';

abstract class DownloaderEvent extends Equatable {
  const DownloaderEvent();
}

class DownloaderGetVideo extends DownloaderEvent {
  final String videoLink;

  const DownloaderGetVideo(this.videoLink);

  @override
  List<Object?> get props => [videoLink];
}

class DownloaderSaveVideo extends DownloaderEvent {
  final TikTokVideo tikTokVideo;
  final DownloadFormat format;

  const DownloaderSaveVideo({
    required this.tikTokVideo,
    this.format = DownloadFormat.withCredits,
  });

  @override
  List<Object?> get props => [tikTokVideo, format];
}

class DownloaderCancelVideo extends DownloaderEvent {
  final String path;

  const DownloaderCancelVideo(this.path);

  @override
  List<Object?> get props => [path];
}

class DownloaderRetryVideo extends DownloaderEvent {
  final String path;

  const DownloaderRetryVideo(this.path);

  @override
  List<Object?> get props => [path];
}

class DownloaderDeleteVideo extends DownloaderEvent {
  final String path;

  const DownloaderDeleteVideo(this.path);

  @override
  List<Object?> get props => [path];
}

/// La app pasó a segundo plano (`away: true`) o volvió a verse.
class DownloaderAppLifecycleChanged extends DownloaderEvent {
  final bool away;

  const DownloaderAppLifecycleChanged({required this.away});

  @override
  List<Object?> get props => [away];
}

