import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';

/// Marcador de posición con la forma de la vista previa mientras se busca el video.
/// Medidas del marcador de posición; reproducen las de la vista previa real.
const double _coverWidth = 92;
const double _titleLine = 16;
const double _titleShort = 140;
const double _statLine = 12;
const double _statWidths = 100;

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
        block(
          width: _coverWidth,
          height: _coverWidth * 16 / 9,
          radius: AppRadii.md,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              block(height: _titleLine),
              const SizedBox(height: AppSpacing.sm),
              block(width: _titleShort, height: _titleLine),
              const SizedBox(height: AppSpacing.md),
              block(width: _statWidths - 10, height: _statLine),
              const SizedBox(height: AppSpacing.md),
              block(width: _statWidths + 10, height: _statLine),
              const SizedBox(height: AppSpacing.sm),
              block(width: _statWidths, height: _statLine),
            ],
          ),
        ),
      ],
    );

    return Semantics(
      liveRegion: true,
      label: context.strings.searching,
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
