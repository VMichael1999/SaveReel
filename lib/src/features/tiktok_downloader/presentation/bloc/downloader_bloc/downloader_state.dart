part of 'downloader_bloc.dart';

abstract class DownloaderState extends Equatable {
  const DownloaderState();
}

class DownloaderInitial extends DownloaderState {
  @override
  List<Object> get props => [];
}

class DownloaderGetVideoLoading extends DownloaderState {
  const DownloaderGetVideoLoading();

  @override
  List<Object?> get props => [];
}

class DownloaderGetVideoSuccess extends DownloaderState {
  final TikTokVideo tikTokVideo;

  const DownloaderGetVideoSuccess(this.tikTokVideo);

  @override
  List<Object?> get props => [tikTokVideo];
}

class DownloaderGetVideoFailure extends DownloaderState {
  final String message;

  /// Si la causa es pasajera y conviene ofrecer «Reintentar».
  final bool retryable;

  const DownloaderGetVideoFailure(this.message, {this.retryable = false});

  @override
  List<Object?> get props => [message, retryable];
}

class DownloaderSaveVideoLoading extends DownloaderState {
  const DownloaderSaveVideoLoading();

  @override
  List<Object?> get props => [];
}

class DownloaderSaveVideoProgress extends DownloaderState {
  final String path;
  final int receivedBytes;
  final int totalBytes;

  const DownloaderSaveVideoProgress({
    required this.path,
    required this.receivedBytes,
    required this.totalBytes,
  });

  @override
  List<Object?> get props => [path, receivedBytes, totalBytes];
}

class DownloaderSaveVideoSuccess extends DownloaderState {
  final String message;
  final String path;

  const DownloaderSaveVideoSuccess({required this.message, required this.path});

  @override
  List<Object?> get props => [message, path];
}

class DownloaderSaveVideoFailure extends DownloaderState {
  final String message;

  const DownloaderSaveVideoFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class DownloaderSaveVideoCancelled extends DownloaderState {
  final String path;

  const DownloaderSaveVideoCancelled(this.path);

  @override
  List<Object?> get props => [path];
}

class DownloaderVideoDeleted extends DownloaderState {
  final String path;

  const DownloaderVideoDeleted(this.path);

  @override
  List<Object?> get props => [path];
}
