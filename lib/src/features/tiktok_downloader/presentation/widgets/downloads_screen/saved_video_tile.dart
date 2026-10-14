import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../domain/entities/video_item.dart';
import 'download_thumbnail.dart';

/// Un video que ya estaba guardado de antes. La biblioteca lo reemplaza.
class SavedVideoTile extends StatelessWidget {
  const SavedVideoTile({super.key, required this.video});

  final VideoItem video;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          DownloadThumbnail.file(video.thumbnailPath ?? ''),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.savedVideo, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, AppSizes.touch),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      size: AppSpacing.lg,
                    ),
                    label: const Text(AppStrings.viewVideo),
                    onPressed:
                        () => Navigator.of(
                          context,
                        ).pushNamed(Routes.viewVideo, arguments: video.path),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppStrings.shareVideo,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed:
                () => SharePlus.instance.share(
                  ShareParams(files: [XFile(video.path)]),
                ),
          ),
        ],
      ),
    );
  }
}
