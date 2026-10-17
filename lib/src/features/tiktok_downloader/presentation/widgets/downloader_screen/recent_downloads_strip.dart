import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../domain/entities/saved_video.dart';
import '../../bloc/library_cubit/library_cubit.dart';
import '../library_screen/library_thumbnail.dart';

/// Los últimos videos guardados, en filas de tres, para reproducirlos con un
/// toque. Con seis se llena la parte baja del inicio.
class RecentDownloadsStrip extends StatelessWidget {
  const RecentDownloadsStrip({super.key});

  static const int _perRow = 3;
  static const int _count = 6;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final recents =
            state.videos.where((v) => !v.isAudio).take(_count).toList();
        if (recents.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.strings.recents,
                  style: theme.textTheme.titleMedium,
                ),
                TextButton(
                  onPressed:
                      () => Navigator.of(context).pushNamed(Routes.library),
                  child: Text(
                    context.strings.seeAll,
                    style: TextStyle(color: context.colors.muted),
                  ),
                ),
              ],
            ),
            for (var start = 0; start < recents.length; start += _perRow) ...[
              if (start > 0) const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (var i = 0; i < _perRow; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child:
                          start + i < recents.length
                              ? _RecentThumb(video: recents[start + i])
                              : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _RecentThumb extends StatelessWidget {
  const _RecentThumb({required this.video});

  final SavedVideo video;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.strings.libraryTile(
        video.title,
        pieces: video.isGallery ? video.files.length : null,
      ),
      excludeSemantics: true,
      child: GestureDetector(
        onTap:
            () => Navigator.of(context).pushNamed(
              Routes.viewVideo,
              arguments: videoPlayerArgsFor(context, video),
            ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: LibraryThumbnail(path: video.coverPath),
          ),
        ),
      ),
    );
  }
}
