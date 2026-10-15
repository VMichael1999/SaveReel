import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/helpers/dir_helper.dart';
import '../../../../../core/utils/app_enums.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/widgets/app_message.dart';
import '../../../domain/entities/saved_video.dart';
import '../../bloc/downloader_bloc/downloader_bloc.dart';
import '../video_player/delete_video_dialog.dart';

/// Hoja que se abre al mantener pulsada una miniatura: compartir, guardar en
/// la galería y eliminar, sin tener que abrir el video.
Future<void> showLibraryActionsSheet(
  BuildContext context,
  SavedVideo video, {
  Future<void> Function(String path) saveToGallery =
      DirHelper.saveMediaToGallery,
  VoidCallback? onSelect,
}) {
  HapticFeedback.mediumImpact().catchError((_) {});
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  final messenger = context;
  return showModalBottomSheet<void>(
    context: context,
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
    builder:
        (sheetContext) => _LibraryActions(
          video: video,
          onSelect:
              onSelect == null
                  ? null
                  : () {
                    Navigator.of(sheetContext).pop();
                    onSelect();
                  },
          onShare: () {
            Navigator.of(sheetContext).pop();
            final handle = video.authorHandle;
            SharePlus.instance.share(
              ShareParams(
                files: [
                  for (final path
                      in video.isGallery ? video.files : [video.path])
                    XFile(path),
                ],
                text: handle == null ? null : context.strings.shareText(handle),
              ),
            );
          },
          onSaveToGallery: () async {
            Navigator.of(sheetContext).pop();
            try {
              for (final path in video.isGallery ? video.files : [video.path]) {
                await saveToGallery(path);
              }
              if (!messenger.mounted) return;
              showAppMessage(
                messenger,
                msg: context.strings.galleryDone,
                type: MessageType.success,
              );
            } catch (_) {
              if (!messenger.mounted) return;
              showAppMessage(
                messenger,
                msg: context.strings.galleryFailed,
                type: MessageType.error,
              );
            }
          },
          onDelete: () async {
            final bloc = messenger.read<DownloaderBloc>();
            Navigator.of(sheetContext).pop();
            if (!messenger.mounted) return;
            final confirmed = await confirmDeleteVideo(
              messenger,
              hasGalleryCopy: bloc.isInGallery(video.path),
            );
            if (confirmed) bloc.add(DownloaderDeleteVideo(video.path));
          },
        ),
  );
}

class _LibraryActions extends StatelessWidget {
  const _LibraryActions({
    required this.video,
    required this.onSelect,
    required this.onShare,
    required this.onSaveToGallery,
    required this.onDelete,
  });

  final SavedVideo video;
  final VoidCallback? onSelect;
  final VoidCallback onShare;
  final VoidCallback onSaveToGallery;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final title = video.title?.trim();

    return Padding(
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
          Semantics(
            header: true,
            child: Text(
              title == null || title.isEmpty
                  ? context.strings.untitledVideo
                  : title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          if (video.authorHandle != null)
            Text(
              '@${video.authorHandle}',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
          const SizedBox(height: AppSpacing.md),
          if (onSelect != null)
            _ActionRow(
              icon: Icons.check_circle_outline_rounded,
              label: context.strings.select,
              onTap: onSelect!,
            ),
          _ActionRow(
            icon: Icons.ios_share_rounded,
            label: context.strings.share,
            onTap: onShare,
          ),
          if (!video.isAudio)
            _ActionRow(
              icon: Icons.photo_library_outlined,
              label: context.strings.saveToGallery,
              onTap: onSaveToGallery,
            ),
          _ActionRow(
            icon: Icons.delete_outline_rounded,
            label: context.strings.delete,
            color: colors.failed,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: tint),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: tint),
      ),
      onTap: onTap,
    );
  }
}
