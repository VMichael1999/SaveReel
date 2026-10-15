import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_text.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/video_link.dart';
import '../../../../../core/widgets/network_mark.dart';
import '../../../domain/entities/tiktok_video.dart';
import '../../../domain/entities/video_data.dart';
import '../../bloc/downloader_bloc/downloader_bloc.dart';
import '../../bloc/settings_cubit/settings_cubit.dart';
import '../../models/download_format.dart';
import 'format_option.dart';
import 'mobile_data_dialog.dart';

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

  /// Peso en bytes de cada formato; falta el que aún no responde.
  final Map<DownloadFormat, int> _sizes = {};

  VideoData get _data => widget.video.videoData!;

  @override
  void initState() {
    super.initState();
    final preferred = context.read<SettingsCubit>().state.defaultFormat;
    _format =
        _data.isGallery
            ? DownloadFormat.gallery
            : preferred.isAvailableIn(_data)
            ? preferred
            : DownloadFormat.values.firstWhere(
              (f) => f.isAvailableIn(_data),
              orElse: () => DownloadFormat.withCredits,
            );
    _loadSizes();
  }

  /// Los pesos que el servicio ya informó; el resto se pregunta al servidor
  /// de video, que no siempre contesta.
  void _useKnownSizes() {
    final known = {
      DownloadFormat.withCredits: _data.wmPlayBytes,
      DownloadFormat.noWatermark: _data.playBytes,
    };
    for (final entry in known.entries) {
      final bytes = entry.value;
      if (bytes != null && bytes > 0) _sizes[entry.key] = bytes;
    }
  }

  Future<void> _loadSizes() async {
    _useKnownSizes();
    final bloc = context.read<DownloaderBloc>();
    for (final format in DownloadFormat.values) {
      if (format == DownloadFormat.gallery) continue;
      if (!format.isAvailableIn(_data) || _sizes.containsKey(format)) continue;
      bloc.fileSizeOf(format.urlOf(_data)).then((bytes) {
        if (bytes != null && mounted) {
          setState(() => _sizes[format] = bytes);
        }
      });
    }
  }

  String? _sizeText(DownloadFormat format) {
    final bytes = _sizes[format];
    return bytes == null ? null : formatMegabytes(bytes);
  }

  Future<void> _download() async {
    final bloc = context.read<DownloaderBloc>();
    final allowed = await confirmMobileData(
      context,
      policy: context.read<SettingsCubit>().state.mobileData,
      bytes: _sizes[_format],
    );
    if (!allowed) return;
    bloc.add(DownloaderSaveVideo(tikTokVideo: widget.video, format: _format));
  }

  bool get _onlyPhotos => _data.photoCount == _data.gallery.length;

  String get _buttonLabel {
    if (_format == DownloadFormat.gallery) {
      return AppStrings.downloadGallery(
        _data.gallery.length,
        onlyPhotos: _onlyPhotos,
      );
    }
    final base =
        _format.isAudio ? AppStrings.downloadAudio : AppStrings.downloadVideo;
    final size = _sizeText(_format);
    return size == null ? base : '$base · $size';
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
            if (_data.isGallery) ...[
              FormatOption(
                title:
                    _onlyPhotos
                        ? AppStrings.formatGallery
                        : AppStrings.formatGalleryMixed,
                subtitle:
                    _data.network == VideoNetwork.instagram
                        ? AppStrings.formatGalleryHintInstagram
                        : AppStrings.formatGalleryHintTikTok,
                selected: _format == DownloadFormat.gallery,
                size: AppStrings.galleryCount(
                  _data.gallery.length,
                  onlyPhotos: _onlyPhotos,
                ),
                onTap: () => setState(() => _format = DownloadFormat.gallery),
              ),
              if (DownloadFormat.audio.isAvailableIn(_data)) ...[
                const SizedBox(height: AppSpacing.sm),
                FormatOption(
                  title: AppStrings.formatAudio,
                  subtitle: AppStrings.formatAudioHint,
                  selected: _format == DownloadFormat.audio,
                  size: _sizeText(DownloadFormat.audio),
                  onTap: () => setState(() => _format = DownloadFormat.audio),
                ),
              ],
            ] else if (_data.network == VideoNetwork.instagram)
              FormatOption(
                title: AppStrings.formatInstagramVideo,
                subtitle: AppStrings.formatInstagramVideoHint,
                selected: true,
                size: _sizeText(DownloadFormat.noWatermark),
                onTap: () {},
              )
            else ...[
              FormatOption(
                title: AppStrings.formatWithCredits,
                subtitle:
                    handle == null
                        ? AppStrings.formatWithCreditsNoAuthor
                        : AppStrings.formatWithCreditsHint(handle),
                selected: _format == DownloadFormat.withCredits,
                size: _sizeText(DownloadFormat.withCredits),
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
                size: _sizeText(DownloadFormat.noWatermark),
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
                size: _sizeText(DownloadFormat.audio),
                onTap:
                    DownloadFormat.audio.isAvailableIn(_data)
                        ? () => setState(() => _format = DownloadFormat.audio)
                        : null,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: canDownload ? _download : null,
              icon: const Icon(Icons.download_rounded),
              label: Text(_buttonLabel),
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
                data.originCover.isNotEmpty || !data.isGallery
                    ? data.originCover
                    : data.gallery.first.url,
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
              if (data.duration > 0) ...[
                stat(formatDuration(data.duration), AppStrings.durationLabel),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (data.playCount > 0) ...[
                stat(formatCount(data.playCount), AppStrings.playsLabel),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (data.downloadCount > 0)
                stat(
                  formatCount(data.downloadCount),
                  AppStrings.downloadsLabel,
                ),
              if (data.isGallery) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppStrings.galleryCount(
                    data.gallery.length,
                    onlyPhotos: data.photoCount == data.gallery.length,
                  ),
                  style: value,
                ),
              ],
              if (data.duration <= 0 &&
                  data.playCount <= 0 &&
                  data.downloadCount <= 0)
                Row(
                  children: [
                    NetworkMark(network: data.network, size: AppSizes.iconSm),
                    const SizedBox(width: AppSpacing.xs),
                    Text(NetworkMark.labelOf(data.network), style: label),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
