import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_text.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/download_item.dart';
import '../../bloc/downloader_bloc/downloader_bloc.dart';
import 'download_thumbnail.dart';

/// Una descarga en curso: avance real, MB, porcentaje y tiempo restante.
class ActiveDownloadTile extends StatelessWidget {
  const ActiveDownloadTile({super.key, required this.item});

  final DownloadItem item;

  String _status(BuildContext context) {
    final progress = item.progress;
    if (progress == null) return context.strings.downloadingNow;
    if (item.isGallery) {
      final current = (item.unitsDone + 1).clamp(1, item.unitsTotal);
      return [
        context.strings.galleryProgress(current, item.unitsTotal),
        '${(progress * 100).floor()} %',
      ].join(' · ');
    }
    final parts = [
      context.strings.bytesOf(
        formatMegabytes(item.receivedBytes, withUnit: false),
        formatMegabytes(item.totalBytes),
      ),
      '${(progress * 100).floor()} %',
    ];
    final started = item.startedAt;
    if (started != null) {
      final remaining = formatRemaining(
        strings: context.strings,
        elapsed: DateTime.now().difference(started),
        receivedBytes: item.receivedBytes,
        totalBytes: item.totalBytes,
      );
      if (remaining != null) parts.add(remaining);
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final data = item.video.videoData!;
    final progress = item.progress;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DownloadThumbnail.network(data.originCover),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Semantics(
              container: true,
              label: data.title,
              value: progress == null ? null : '${(progress * 100).floor()} %',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Sin tamaño conocido la barra queda indefinida.
                  LinearProgressIndicator(
                    value: progress,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _status(context),
                    style: theme.textTheme.bodySmall?.tabular.copyWith(
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: context.strings.cancelDownload,
            icon: const Icon(Icons.close_rounded),
            onPressed:
                () => context.read<DownloaderBloc>().add(
                  DownloaderCancelVideo(item.path),
                ),
          ),
        ],
      ),
    );
  }
}
