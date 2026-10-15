import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../../config/theme/app_text.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/utils/formatters.dart';

/// Barra de avance con los tiempos `0:12` y `0:34`.
class PlayerScrubber extends StatefulWidget {
  const PlayerScrubber({super.key, required this.controller});

  final VideoPlayerController controller;

  @override
  State<PlayerScrubber> createState() => _PlayerScrubberState();
}

class _PlayerScrubberState extends State<PlayerScrubber> {
  /// Posición mientras el dedo arrastra, en milisegundos.
  double? _dragMs;

  @override
  Widget build(BuildContext context) {
    final timeStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.tabular.copyWith(color: AppOverlay.onVideoMuted);

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final totalMs = value.duration.inMilliseconds.toDouble();
        final currentMs = (_dragMs ?? value.position.inMilliseconds.toDouble())
            .clamp(0.0, totalMs <= 0 ? 1.0 : totalMs);
        final now = Duration(milliseconds: currentMs.round());

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: AppOverlay.onVideo,
                inactiveTrackColor: AppOverlay.track,
                thumbColor: AppOverlay.onVideo,
                overlayColor: AppOverlay.actionFill,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                min: 0,
                max: totalMs <= 0 ? 1 : totalMs,
                value: currentMs,
                semanticFormatterCallback:
                    (v) => AppStrings.playerPosition(
                      formatDuration(
                        Duration(milliseconds: v.round()).inSeconds,
                      ),
                      formatDuration(value.duration.inSeconds),
                    ),
                onChanged:
                    totalMs <= 0 ? null : (v) => setState(() => _dragMs = v),
                onChangeEnd: (v) async {
                  await widget.controller.seekTo(
                    Duration(milliseconds: v.round()),
                  );
                  if (mounted) setState(() => _dragMs = null);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(now.inSeconds), style: timeStyle),
                  Text(
                    formatDuration(value.duration.inSeconds),
                    style: timeStyle,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
