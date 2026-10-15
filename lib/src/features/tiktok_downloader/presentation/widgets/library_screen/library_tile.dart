import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_text.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/network_mark.dart';
import '../../../domain/entities/saved_video.dart';
import '../../screens/video_player_screen.dart';
import '../../models/video_player_args.dart';
import '../../screens/gallery_viewer_screen.dart';
import 'library_actions_sheet.dart';
import 'library_thumbnail.dart';

/// Pantalla que abre un video guardado: el visor si es una galería.
Widget openerFor(VideoPlayerArgs args) =>
    args.isGallery
        ? GalleryViewerScreen(args: args)
        : VideoPlayerScreen(args: args);

/// Una miniatura de la cuadrícula. Se expande al reproductor al tocarla.
class LibraryTile extends StatelessWidget {
  const LibraryTile({
    super.key,
    required this.video,
    this.selecting = false,
    this.selected = false,
    this.onToggle,
    this.onStartSelecting,
  });

  final SavedVideo video;

  /// Modo selección: tocar marca o desmarca en lugar de abrir el video.
  final bool selecting;
  final bool selected;
  final VoidCallback? onToggle;

  /// Para empezar a seleccionar desde la hoja de acciones, con este elegido.
  final VoidCallback? onStartSelecting;

  void _openActions(BuildContext context) =>
      showLibraryActionsSheet(context, video, onSelect: onStartSelecting);

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
          (context, _) => openerFor(videoPlayerArgsFor(context, video)),
      closedBuilder:
          (context, open) => Semantics(
            button: true,
            selected: selecting ? selected : null,
            label: context.strings.libraryTile(
              video.title,
              isAudio: video.isAudio,
              pieces: video.isGallery ? video.files.length : null,
              duration:
                  video.durationSeconds == null
                      ? null
                      : formatDuration(video.durationSeconds!),
            ),
            excludeSemantics: true,
            onTap: selecting ? onToggle : open,
            onLongPress: selecting ? onToggle : () => _openActions(context),
            child: InkWell(
              onTap: selecting ? onToggle : open,
              onLongPress: selecting ? onToggle : () => _openActions(context),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LibraryThumbnail(path: video.coverPath),
                  Positioned(
                    left: AppSpacing.sm,
                    top: AppSpacing.sm,
                    child: _Badge(
                      child: NetworkMark(
                        network: video.source,
                        size: AppSizes.iconBadge,
                      ),
                    ),
                  ),
                  if (video.isGallery)
                    Positioned(
                      left: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: _Badge(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_library_outlined,
                              size: AppSizes.iconBadge,
                              color: AppOverlay.onVideo,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${video.files.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.tabular
                                  .copyWith(color: AppOverlay.onVideo),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (video.durationSeconds != null)
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
                  if (selecting)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ColoredBox(
                          color:
                              selected
                                  ? AppOverlay.controlFill
                                  : AppOverlay.clear,
                        ),
                      ),
                    ),
                  if (selecting)
                    Positioned(
                      right: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: _SelectionMark(selected: selected),
                    ),
                  if (video.isAudio)
                    Positioned(
                      right: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: _Badge(
                        child: Icon(
                          Icons.music_note_rounded,
                          size: AppSizes.iconBadge,
                          color: AppOverlay.onVideo,
                          semanticLabel: context.strings.audioBadge,
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

/// Círculo de la esquina: vacío si no está elegido, con visto si lo está.
class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.accent : AppOverlay.controlFill,
        border: Border.all(
          color: selected ? colors.accent : AppOverlay.onVideo,
          width: 2,
        ),
      ),
      child: SizedBox.square(
        dimension: AppSizes.selectMark,
        child:
            selected
                ? Icon(
                  Icons.check_rounded,
                  size: AppSizes.iconSm,
                  color: colors.onAccent,
                )
                : null,
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
