import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_text.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/tiktok_video.dart';
import '../../../domain/entities/video_data.dart';
import '../../bloc/downloader_bloc/downloader_bloc.dart';
import '../../models/download_format.dart';
import 'format_option.dart';

/// Abre la vista previa como una hoja que sube desde abajo.
Future<void> showVideoPreviewSheet(BuildContext context, TikTokVideo video) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle:
        reduceMotion
            ? AnimationStyle.noAnimation
            : AnimationStyle(
              duration: AppMotion.sheet,
              curve: AppMotion.emphasized,
              reverseDuration: AppMotion.base,
              reverseCurve: AppMotion.exit,
            ),
    builder: (_) => VideoPreviewSheet(video: video),
  );
}

class VideoPreviewSheet extends StatefulWidget {
  const VideoPreviewSheet({super.key, required this.video});

  final TikTokVideo video;

  @override
  State<VideoPreviewSheet> createState() => _VideoPreviewSheetState();
}

class _VideoPreviewSheetState extends State<VideoPreviewSheet> {
  late DownloadFormat _format;

  VideoData get _data => widget.video.videoData!;

  @override
  void initState() {
    super.initState();
    _format = DownloadFormat.values.firstWhere(
      (f) => f.isAvailableIn(_data),
      orElse: () => DownloadFormat.withCredits,
    );
  }

  void _download() {
    context.read<DownloaderBloc>().add(
      DownloaderSaveVideo(tikTokVideo: widget.video, format: _format),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final handle = _data.authorHandle;
    final canDownload = _format.isAvailableIn(_data);

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      label: AppStrings.previewSheetLabel,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(data: _data),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.formatLabel,
              style: theme.textTheme.labelSmall?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: AppSpacing.sm),
            FormatOption(
              title: AppStrings.formatWithCredits,
              subtitle:
                  handle == null
                      ? AppStrings.formatWithCreditsNoAuthor
                      : AppStrings.formatWithCreditsHint(handle),
              selected: _format == DownloadFormat.withCredits,
              onTap:
                  DownloadFormat.withCredits.isAvailableIn(_data)
                      ? () =>
                          setState(() => _format = DownloadFormat.withCredits)
                      : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            FormatOption(
              title: AppStrings.formatNoWatermark,
              subtitle: AppStrings.formatNoWatermarkHint,
              selected: _format == DownloadFormat.noWatermark,
              onTap:
                  DownloadFormat.noWatermark.isAvailableIn(_data)
                      ? () =>
                          setState(() => _format = DownloadFormat.noWatermark)
                      : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            FormatOption(
              title: AppStrings.formatAudio,
              subtitle: AppStrings.formatAudioHint,
              selected: _format == DownloadFormat.audio,
              onTap:
                  DownloadFormat.audio.isAvailableIn(_data)
                      ? () => setState(() => _format = DownloadFormat.audio)
                      : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: canDownload ? _download : null,
              icon: const Icon(Icons.download_rounded),
              label: Text(
                _format.isAudio
                    ? AppStrings.downloadAudio
                    : AppStrings.downloadVideo,
              ),
            ),
            if (handle != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.creditNote(handle),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.data});

  final VideoData data;

  static const double _coverWidth = 92;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final handle = data.authorHandle;
    final label = theme.textTheme.bodySmall?.copyWith(color: colors.muted);
    final value = theme.textTheme.labelMedium?.tabular;

    Widget stat(String number, String text) => Text.rich(
      TextSpan(
        children: [
          TextSpan(text: number, style: value),
          TextSpan(text: ' $text', style: label),
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _coverWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Image.network(
                data.originCover,
                fit: BoxFit.cover,
                semanticLabel: AppStrings.coverLabel,
                errorBuilder:
                    (_, __, ___) => ColoredBox(
                      color: colors.raised,
                      child: Icon(Icons.movie_outlined, color: colors.muted),
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title.trim().isEmpty
                    ? AppStrings.untitledVideo
                    : data.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              if (handle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '@$handle',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.muted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              stat(formatDuration(data.duration), AppStrings.durationLabel),
              const SizedBox(height: AppSpacing.xs),
              stat(formatCount(data.playCount), AppStrings.playsLabel),
              const SizedBox(height: AppSpacing.xs),
              stat(formatCount(data.downloadCount), AppStrings.downloadsLabel),
            ],
          ),
        ),
      ],
    );
  }
}
