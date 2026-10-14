import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../config/theme/app_tokens.dart';
import '../../../../core/helpers/dir_helper.dart';
import '../../../../core/utils/app_enums.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_message.dart';
import '../bloc/downloader_bloc/downloader_bloc.dart';
import '../models/video_player_args.dart';
import '../widgets/video_player/delete_video_dialog.dart';
import '../widgets/video_player/player_action.dart';
import '../widgets/video_player/player_scrubber.dart';

/// Reproductor a pantalla completa, con el autor siempre visible y las
/// acciones (compartir, galería, eliminar) con texto.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.args});

  final VideoPlayerArgs args;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;
  late bool _inGallery = widget.args.inGallery;

  VideoPlayerArgs get _args => widget.args;

  /// Sombra del texto para que se lea también sobre videos claros.
  static const List<Shadow> _textShadow = [
    Shadow(color: AppOverlay.shadeBottom, blurRadius: AppSpacing.sm),
  ];

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(_args.path));
    _controller
        .initialize()
        .then((_) async {
          if (!mounted) return;
          await _controller.setLooping(true);
          await _controller.play();
          if (mounted) setState(() => _ready = true);
        })
        .catchError((Object _) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_ready) return;
    _controller.value.isPlaying ? _controller.pause() : _controller.play();
  }

  Future<void> _share() {
    final handle = _args.authorHandle;
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(_args.path)],
        text: handle == null ? null : AppStrings.shareText(handle),
      ),
    );
  }

  Future<void> _saveToGallery() async {
    try {
      await DirHelper.saveVideoToGallery(_args.path);
      if (!mounted) return;
      setState(() => _inGallery = true);
      showAppMessage(
        context,
        msg: AppStrings.galleryDone,
        type: MessageType.success,
      );
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        msg: AppStrings.galleryFailed,
        type: MessageType.error,
      );
    }
  }

  Future<void> _delete() async {
    final bloc = context.read<DownloaderBloc>();
    final navigator = Navigator.of(context);
    final confirmed = await confirmDeleteVideo(
      context,
      hasGalleryCopy: _inGallery,
    );
    if (!confirmed) return;
    bloc.add(DownloaderDeleteVideo(_args.path));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppOverlay.videoBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _Backdrop(
              controller: _controller,
              ready: _ready,
              failed: _failed,
              isAudio: _args.isAudio,
              onTap: _togglePlay,
            ),
            if (_ready)
              IgnorePointer(
                child: Center(
                  child: ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: _controller,
                    builder:
                        (context, value, _) => AnimatedOpacity(
                          opacity: value.isPlaying ? 0 : 1,
                          duration:
                              reduceMotion ? Duration.zero : AppMotion.fast,
                          child: const _BigPlayIcon(),
                        ),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppOverlay.shadeTop, AppOverlay.clear],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: IconButton.filled(
                        tooltip: AppStrings.back,
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: IconButton.styleFrom(
                          backgroundColor: AppOverlay.controlFill,
                          foregroundColor: AppOverlay.onVideo,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppOverlay.clear,
                      AppOverlay.shadeTop,
                      AppOverlay.shadeBottom,
                    ],
                    stops: [0, 0.2, 0.5],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_args.title != null)
                          Text(
                            _args.title!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppOverlay.onVideo,
                              shadows: _textShadow,
                            ),
                          ),
                        if (_args.authorHandle != null)
                          Text(
                            '@${_args.authorHandle}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppOverlay.onVideo,
                              shadows: _textShadow,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.md),
                        if (_ready) PlayerScrubber(controller: _controller),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: PlayerAction(
                                icon: Icons.ios_share_rounded,
                                label: AppStrings.share,
                                onTap: _share,
                              ),
                            ),
                            if (!_args.isAudio) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: PlayerAction(
                                  icon:
                                      _inGallery
                                          ? Icons.check_rounded
                                          : Icons.photo_library_outlined,
                                  iconColor:
                                      _inGallery ? AppOverlay.done : null,
                                  label:
                                      _inGallery
                                          ? AppStrings.inGallery
                                          : AppStrings.saveToGallery,
                                  onTap: _inGallery ? null : _saveToGallery,
                                ),
                              ),
                            ],
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: PlayerAction(
                                icon: Icons.delete_outline_rounded,
                                label: AppStrings.delete,
                                onTap: _delete,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El video, o lo que lo reemplaza mientras carga, si falla o si es un audio.
class _Backdrop extends StatelessWidget {
  const _Backdrop({
    required this.controller,
    required this.ready,
    required this.failed,
    required this.isAudio,
    required this.onTap,
  });

  final VideoPlayerController controller;
  final bool ready;
  final bool failed;
  final bool isAudio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (failed) {
      return Center(
        child: Text(
          AppStrings.cannotPlay,
          style: theme.textTheme.bodyLarge?.copyWith(color: AppOverlay.onVideo),
        ),
      );
    }
    if (!ready) {
      return const Center(
        child: CircularProgressIndicator(color: AppOverlay.onVideo),
      );
    }
    final Widget content =
        isAudio
            ? const Center(
              child: Icon(
                Icons.music_note_rounded,
                size: AppSizes.backdropIcon,
                color: AppOverlay.onVideoMuted,
              ),
            )
            : _VideoSurface(controller: controller);

    return Semantics(
      button: true,
      label: AppStrings.playVideo,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _VideoSurface extends StatelessWidget {
  const _VideoSurface({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    final portrait = size.height >= size.width;
    return FittedBox(
      // Los videos verticales llenan la pantalla; los horizontales no se recortan.
      fit: portrait ? BoxFit.cover : BoxFit.contain,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _BigPlayIcon extends StatelessWidget {
  const _BigPlayIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.playButton,
      height: AppSizes.playButton,
      decoration: const BoxDecoration(
        color: AppOverlay.controlFill,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        size: AppSizes.playIcon,
        color: AppOverlay.onVideo,
      ),
    );
  }
}
