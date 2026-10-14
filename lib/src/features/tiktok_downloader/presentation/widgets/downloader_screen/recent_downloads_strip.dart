import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../domain/entities/video_item.dart';
import '../../bloc/downloader_bloc/downloader_bloc.dart';

/// Los últimos videos guardados, para reproducirlos con un toque.
class RecentDownloadsStrip extends StatelessWidget {
  const RecentDownloadsStrip({super.key});

  static const int _count = 3;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloaderBloc, DownloaderState>(
      buildWhen: (_, state) => state is OldDownloadsLoadingSuccess,
      builder: (context, _) {
        final recents = _latest(context.read<DownloaderBloc>().oldDownloads);
        if (recents.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.recents, style: theme.textTheme.titleMedium),
                TextButton(
                  onPressed:
                      () => Navigator.of(context).pushNamed(Routes.downloads),
                  child: Text(
                    AppStrings.seeAll,
                    style: TextStyle(color: context.colors.muted),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                for (final (i, video) in recents.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _RecentThumb(video: video)),
                ],
                for (var i = recents.length; i < _count; i++) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  List<VideoItem> _latest(List<VideoItem> all) {
    final sorted = [...all]..sort((a, b) {
      final ma = File(a.path).lastModifiedSync();
      final mb = File(b.path).lastModifiedSync();
      return mb.compareTo(ma);
    });
    return sorted.take(_count).toList();
  }
}

class _RecentThumb extends StatelessWidget {
  const _RecentThumb({required this.video});

  final VideoItem video;

  @override
  Widget build(BuildContext context) {
    final thumbnail = video.thumbnailPath;

    return Semantics(
      button: true,
      label: 'Reproducir video guardado',
      child: GestureDetector(
        onTap:
            () => Navigator.of(
              context,
            ).pushNamed(Routes.viewVideo, arguments: video.path),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child:
                thumbnail == null
                    ? ColoredBox(
                      color: context.colors.raised,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: context.colors.muted,
                      ),
                    )
                    : Image.file(
                      File(thumbnail),
                      fit: BoxFit.cover,
                      cacheWidth: 360,
                    ),
          ),
        ),
      ),
    );
  }
}
