import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_text.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/saved_video.dart';
import '../../screens/video_player_screen.dart';
import 'library_thumbnail.dart';

/// Una miniatura de la cuadrícula. Se expande al reproductor al tocarla.
class LibraryTile extends StatelessWidget {
  const LibraryTile({super.key, required this.video});

  final SavedVideo video;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.sm),
    );

    return OpenContainer<void>(
      transitionType: ContainerTransitionType.fade,
      transitionDuration: reduceMotion ? Duration.zero : AppMotion.slow,
      closedElevation: 0,
      openElevation: 0,
      closedShape: shape,
      closedColor: colors.line,
      openColor: AppOverlay.videoBackground,
      middleColor: AppOverlay.videoBackground,
      openBuilder:
          (context, _) =>
              VideoPlayerScreen(args: videoPlayerArgsFor(context, video)),
      closedBuilder:
          (context, open) => Semantics(
            button: true,
            label: AppStrings.libraryTile(
              video.title,
              isAudio: video.isAudio,
              duration:
                  video.durationSeconds == null
                      ? null
                      : formatDuration(video.durationSeconds!),
            ),
            excludeSemantics: true,
            onTap: open,
            child: InkWell(
              onTap: open,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LibraryThumbnail(path: video.path),
                  if (video.durationSeconds != null)
                    Positioned(
                      left: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: _Badge(
                        child: Text(
                          formatDuration(video.durationSeconds!),
                          style: Theme.of(context).textTheme.labelSmall?.tabular
                              .copyWith(color: AppOverlay.onVideo),
                        ),
                      ),
                    ),
                  if (video.isAudio)
                    const Positioned(
                      right: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: _Badge(
                        child: Icon(
                          Icons.music_note_rounded,
                          size: AppSizes.iconBadge,
                          color: AppOverlay.onVideo,
                          semanticLabel: AppStrings.audioBadge,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppOverlay.controlFill,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 1,
        ),
        child: child,
      ),
    );
  }
}
