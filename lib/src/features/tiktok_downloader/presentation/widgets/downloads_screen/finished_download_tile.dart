import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_enums.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/download_item.dart';
import '../../bloc/downloader_bloc/downloader_bloc.dart';
import '../../models/download_format.dart';
import 'download_thumbnail.dart';

/// Una descarga terminada o fallida de esta sesión.
class FinishedDownloadTile extends StatelessWidget {
  const FinishedDownloadTile({super.key, required this.item});

  final DownloadItem item;

  bool get _failed => item.status == DownloadStatus.error;

  String _formatName(DownloadFormat? format) => switch (format) {
    DownloadFormat.withCredits => AppStrings.withCreditsShort,
    DownloadFormat.noWatermark => AppStrings.noWatermarkShort,
    DownloadFormat.audio => AppStrings.audioShort,
    null => '',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final data = item.video.videoData!;
    final format = context.read<DownloaderBloc>().formatOf(item.path);
    final isAudio = format == DownloadFormat.audio;
    final size = item.totalBytes > 0 ? formatMegabytes(item.totalBytes) : null;
    final percent = item.progress == null ? 0 : (item.progress! * 100).floor();

    final statusColor = _failed ? colors.failed : colors.done;
    final statusText =
        _failed
            ? (item.failureMessage ?? AppStrings.downloadFall)
            : [
              isAudio ? AppStrings.savedInApp : AppStrings.savedInGallery,
              if (size != null) size,
            ].join(' · ');
    final detail = [
      if (data.authorHandle != null) '@${data.authorHandle}',
      if (_failed && percent > 0)
        AppStrings.stoppedAt(percent)
      else if (_formatName(format).isNotEmpty)
        _formatName(format),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DownloadThumbnail.network(
            data.originCover,
            icon: isAudio ? Icons.music_note_rounded : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _failed
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      size: AppSizes.iconSm,
                      color: statusColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        statusText,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.muted,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                if (_failed)
                  OutlinedButton.icon(
                    style: _pillStyle,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: AppSizes.iconSm,
                    ),
                    label: const Text(AppStrings.retry),
                    onPressed:
                        () => context.read<DownloaderBloc>().add(
                          DownloaderRetryVideo(item.path),
                        ),
                  )
                else
                  OutlinedButton.icon(
                    style: _pillStyle,
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      size: AppSizes.iconSm,
                    ),
                    label: Text(
                      isAudio ? AppStrings.play : AppStrings.viewVideo,
                    ),
                    onPressed:
                        () => Navigator.of(context).pushNamed(
                          Routes.viewVideo,
                          arguments: context
                              .read<DownloaderBloc>()
                              .playerArgsFor(item.path),
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static final ButtonStyle _pillStyle = OutlinedButton.styleFrom(
    minimumSize: const Size(0, AppSizes.touch),
    shape: const StadiumBorder(),
  );
}
