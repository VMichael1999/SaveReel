import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../domain/entities/saved_video.dart';
import '../../bloc/library_cubit/library_cubit.dart';
import '../library_screen/library_thumbnail.dart';

/// Los últimos videos guardados, para reproducirlos con un toque.
class RecentDownloadsStrip extends StatelessWidget {
  const RecentDownloadsStrip({super.key});

  static const int _count = 3;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final recents = state.videos.where((v) => !v.isAudio).take(_count);
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
