import '../../../../core/utils/app_enums.dart';
import 'tiktok_video.dart';
import 'package:equatable/equatable.dart';

class DownloadItem extends Equatable {
  final TikTokVideo video;
  final DownloadStatus status;
  final String path;

  /// Bytes recibidos y totales; el total es 0 mientras se desconoce.
  final int receivedBytes;
  final int totalBytes;

  /// Momento en que empezó la descarga, para estimar el tiempo restante.
  final DateTime? startedAt;

  /// Qué falló, si la descarga terminó con error.
  final String? failureMessage;

  const DownloadItem({
    required this.video,
    required this.status,
    required this.path,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.startedAt,
    this.failureMessage,
  });

  /// Avance de 0 a 1, o nulo si el servidor no informó el tamaño.
  double? get progress =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : null;

  DownloadItem copyWith({
    TikTokVideo? video,
    DownloadStatus? status,
    String? path,
    int? receivedBytes,
    int? totalBytes,
    DateTime? startedAt,
    String? failureMessage,
    bool clearFailure = false,
  }) {
    return DownloadItem(
      video: video ?? this.video,
      status: status ?? this.status,
      path: path ?? this.path,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      startedAt: startedAt ?? this.startedAt,
      failureMessage:
          clearFailure ? null : (failureMessage ?? this.failureMessage),
    );
  }

  @override
  List<Object?> get props => [
        video,
        status,
        path,
        receivedBytes,
        totalBytes,
        startedAt,
        failureMessage,
      ];
}
