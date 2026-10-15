import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/helpers/dir_helper.dart';
import '../../../../../core/utils/app_enums.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/widgets/app_message.dart';
import '../../../domain/entities/saved_video.dart';

/// Los archivos de cada elemento: una galería aporta todas sus piezas.
List<String> filesOf(Iterable<SavedVideo> videos) => [
  for (final video in videos) ...(video.isGallery ? video.files : [video.path]),
];

/// Comparte los elegidos en una sola hoja del sistema.
Future<void> shareSavedVideos(Iterable<SavedVideo> videos) {
  return SharePlus.instance.share(
    ShareParams(files: [for (final path in filesOf(videos)) XFile(path)]),
  );
}

/// Copia a la galería del teléfono los elegidos que no son audio, y avisa.
Future<void> saveSavedVideosToGallery(
  BuildContext context,
  Iterable<SavedVideo> videos, {
  Future<void> Function(String path) saver = DirHelper.saveMediaToGallery,
}) async {
  try {
    for (final path in filesOf(videos.where((v) => !v.isAudio))) {
      await saver(path);
    }
    if (!context.mounted) return;
    showAppMessage(
      context,
      msg: context.strings.galleryDone,
      type: MessageType.success,
    );
  } catch (_) {
    if (!context.mounted) return;
    showAppMessage(
      context,
      msg: context.strings.galleryFailed,
      type: MessageType.error,
    );
  }
}

/// Pide confirmar antes de borrar varios. Devuelve `true` si el usuario acepta.
Future<bool> confirmDeleteMany(BuildContext context, int count) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(context.strings.deleteManyTitle(count)),
          content: Text(context.strings.deleteManyBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.strings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.failed,
              ),
              child: Text(context.strings.delete),
            ),
          ],
        ),
  );
  return confirmed ?? false;
}
