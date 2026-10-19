import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../config/theme/app_tokens.dart';
import '../../../../core/helpers/dir_helper.dart';
import '../../../../core/layout/duo_context.dart';
import '../../../../core/layout/duo_layout.dart';
import '../../../../core/layout/duo_side_bar.dart';
import '../../../../core/layout/duo_split.dart';
import '../../../../core/utils/app_enums.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_message.dart';
import '../bloc/downloader_bloc/downloader_bloc.dart';
import '../bloc/library_cubit/library_cubit.dart';
import '../../domain/entities/saved_video.dart';
import '../models/video_player_args.dart';
import '../widgets/video_player/delete_video_dialog.dart';
import 'library_screen.dart';
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
        text: handle == null ? null : context.strings.shareText(handle),
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
        msg: context.strings.galleryDone,
        type: MessageType.success,
      );
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        msg: context.strings.galleryFailed,
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
    final split = context.duoLayout == DuoLayout.openLandscape;
    // Con el Duo abierto en horizontal, la lista queda a la izquierda y el
    // video en una tarjeta a la derecha. El controlador es de este State y no
    // se recrea al pasar de un diseño a otro.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: split ? null : AppOverlay.videoBackground,
        body:
            split
                ? DuoSplit(
                  left: LibraryScreen(playingPath: _args.path),
                  right: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                    ),
                    child: SafeArea(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                        child: ColoredBox(
                          color: AppOverlay.videoBackground,
                          child: _player(context, compact: true),
                        ),
                      ),
                    ),
                  ),
                  sideBar: _PlayerSideBar(
                    path: _args.path,
                    split: true,
                    onShare: _share,
                    onGallery:
                        _args.isAudio || _inGallery ? null : _saveToGallery,
                    onDelete: _delete,
                  ),
                )
                : _player(context, compact: false),
      ),
    );
  }

  /// El video con su título, el autor, la barra de tiempo y las acciones.
  /// Con [compact] (la tarjeta de la derecha) las acciones y Volver van en la
  /// franja y no se repiten aquí.
  Widget _player(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final sideBar = !compact && context.hasDuoSideBar;

    return Stack(
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
                      duration: reduceMotion ? Duration.zero : AppMotion.fast,
                      child: const _BigPlayIcon(),
                    ),
              ),
            ),
          ),
        if (!compact && !context.hasDuoSideBar)
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
                      tooltip: context.strings.back,
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
                padding: EdgeInsets.fromLTRB(
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
                    if (!compact) ...[
                      const SizedBox(height: AppSpacing.md),
                      _actionRow(context),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (sideBar)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: _PlayerSideBar(path: _args.path),
          ),
      ],
    );
  }

  Widget _actionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PlayerAction(
            icon: Icons.ios_share_rounded,
            label: context.strings.share,
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
              iconColor: _inGallery ? AppOverlay.done : null,
              label:
                  _inGallery
                      ? context.strings.inGallery
                      : context.strings.saveToGallery,
              onTap: _inGallery ? null : _saveToGallery,
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: PlayerAction(
            icon: Icons.delete_outline_rounded,
            label: context.strings.delete,
            onTap: _delete,
          ),
        ),
      ],
    );
  }
}

/// La franja del reproductor. Sobre el video (Duo cerrado) lleva Volver
/// arriba y Favorito abajo; con el Duo abierto, junto a la lista, lleva las
/// acciones del video: Favorito, Compartir, Guardar en galería y Eliminar.
class _PlayerSideBar extends StatelessWidget {
  const _PlayerSideBar({
    required this.path,
    this.split = false,
    this.onShare,
    this.onGallery,
    this.onDelete,
  });

  final String path;
  final bool split;
  final VoidCallback? onShare;
  final VoidCallback? onGallery;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      buildWhen: (a, b) => _favorite(a.videos) != _favorite(b.videos),
      builder: (context, state) {
        final favorite = _favorite(state.videos);
        final favoriteAction = DuoAction(
          icon:
              favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          tooltip:
              favorite
                  ? context.strings.favoriteRemove
                  : context.strings.favoriteAdd,
          onPressed:
              () => context.read<LibraryCubit>().setFavorite(path, !favorite),
        );
        if (split) {
          return DuoSideBar(
            top: [
              favoriteAction,
              DuoAction(
                icon: Icons.ios_share_rounded,
                tooltip: context.strings.share,
                onPressed: onShare,
              ),
              if (onGallery != null)
                DuoAction(
                  icon: Icons.photo_library_outlined,
                  tooltip: context.strings.saveToGallery,
                  onPressed: onGallery,
                ),
              DuoAction(
                icon: Icons.delete_outline_rounded,
                tooltip: context.strings.delete,
                onPressed: onDelete,
              ),
            ],
          );
        }
        return DuoSideBar(
          overVideo: true,
          top: [
            DuoAction(
              icon: Icons.arrow_back_rounded,
              tooltip: context.strings.back,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
          bottom: [favoriteAction],
        );
      },
    );
  }

  bool _favorite(List<SavedVideo> videos) =>
      videos.any((v) => v.path == path && v.favorite);
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
          context.strings.cannotPlay,
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
      label: context.strings.playVideo,
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
