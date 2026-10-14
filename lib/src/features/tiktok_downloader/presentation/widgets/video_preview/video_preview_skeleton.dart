import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';

/// Marcador de posición con la forma de la vista previa mientras se busca el video.
class VideoPreviewSkeleton extends StatelessWidget {
  const VideoPreviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget block({double? width, required double height, double radius = 6}) =>
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: colors.line,
            borderRadius: BorderRadius.circular(radius),
          ),
        );

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        block(width: 92, height: 92 * 16 / 9, radius: AppRadii.md),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              block(height: 16),
              const SizedBox(height: AppSpacing.sm),
              block(width: 140, height: 16),
              const SizedBox(height: AppSpacing.md),
              block(width: 90, height: 12),
              const SizedBox(height: AppSpacing.md),
              block(width: 110, height: 12),
              const SizedBox(height: AppSpacing.sm),
              block(width: 100, height: 12),
            ],
          ),
        ),
      ],
    );

    return Semantics(
      liveRegion: true,
      label: AppStrings.searching,
      excludeSemantics: true,
      child:
          reduceMotion
              ? content
              : content
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: AppMotion.shimmer, color: colors.raised),
    );
  }
}
