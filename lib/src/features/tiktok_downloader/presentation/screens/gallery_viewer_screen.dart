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

/// Visor de un slideshow o carrusel guardado: se desliza entre las piezas,
/// las fotos se acercan con los dedos y los videos se reproducen en su lugar.
class GalleryViewerScreen extends StatefulWidget {
  const GalleryViewerScreen({
    super.key,
    required this.args,
    this.saveToGallery = DirHelper.saveMediaToGallery,
  });

  final VideoPlayerArgs args;

  /// Guarda una pieza en la galería del teléfono; se cambia en las pruebas.
  final Future<void> Function(String path) saveToGallery;

  @override
  State<GalleryViewerScreen> createState() => _GalleryViewerScreenState();
}

class _GalleryViewerScreenState extends State<GalleryViewerScreen> {
  final PageController _pages = PageController();
  int _index = 0;

  /// Con una foto ampliada el arrastre la mueve, no cambia de página.
  bool _zoomed = false;
  late bool _inGallery = widget.args.inGallery;

  VideoPlayerArgs get _args => widget.args;
  List<String> get _files => _args.files;

  static const List<Shadow> _textShadow = [
    Shadow(color: AppOverlay.shadeBottom, blurRadius: AppSpacing.sm),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _share() {
    final handle = _args.authorHandle;
    return SharePlus.instance.share(
      ShareParams(
        files: [for (final path in _files) XFile(path)],
        text: handle == null ? null : context.strings.shareText(handle),
      ),
    );
  }

  Future<void> _saveToGallery() async {
    try {
      for (final path in _files) {
        await widget.saveToGallery(path);
      }
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
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppOverlay.videoBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pages,
              physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
              itemCount: _files.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder:
                  (context, i) => _GalleryPage(
                    path: _files[i],
                    active: i == _index,
                    onZoomChanged: (zoomed) => setState(() => _zoomed = zoomed),
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
                    child: Row(
                      children: [
                        IconButton.filled(
                          tooltip: context.strings.back,
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: IconButton.styleFrom(
                            backgroundColor: AppOverlay.controlFill,
                            foregroundColor: AppOverlay.onVideo,
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        Semantics(
                          label: context.strings.galleryPosition(
                            _index + 1,
                            _files.length,
                          ),
                          excludeSemantics: true,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppOverlay.controlFill,
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              child: Text(
                                '${_index + 1} / ${_files.length}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppOverlay.onVideo,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
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
                        Row(
                          children: [
                            Expanded(
                              child: PlayerAction(
                                icon: Icons.ios_share_rounded,
                                label: context.strings.share,
                                onTap: _share,
                              ),
                            ),
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
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: PlayerAction(
                                icon: Icons.delete_outline_rounded,
                                label: context.strings.delete,
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

bool _isVideoFile(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.mp4') || lower.endsWith('.mov');
}

/// Una pieza: foto con zoom, o video que se reproduce mientras es la visible.
class _GalleryPage extends StatelessWidget {
  const _GalleryPage({
    required this.path,
    required this.active,
    required this.onZoomChanged,
  });

  final String path;
  final bool active;
  final ValueChanged<bool> onZoomChanged;

  @override
  Widget build(BuildContext context) {
    if (_isVideoFile(path)) return _VideoPage(path: path, active: active);
    return _ZoomablePhoto(path: path, onZoomChanged: onZoomChanged);
  }
}

/// Foto que se acerca con dos dedos o con doble toque. Lee los toques en
/// crudo, sin entrar en la disputa de gestos, para que con la foto sin
/// ampliar el arrastre siga deslizando entre piezas; ampliada, el arrastre
/// la mueve y el visor deja de cambiar de página.
class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({required this.path, required this.onZoomChanged});

  final String path;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  static const double _maxScale = 4;
  static const double _doubleTapScale = 2.5;

  final Map<int, Offset> _pointers = {};
  double _scale = 1;
  Offset _offset = Offset.zero;
  double _pinchStartDistance = 0;
  double _pinchStartScale = 1;

  bool get _zoomed => _scale > 1.01;

  double _distance() {
    final points = _pointers.values.take(2).toList();
    return (points[0] - points[1]).distance;
  }

  Offset _clamp(Offset offset, double scale) {
    final size = context.size ?? Size.zero;
    final dx = size.width * (scale - 1) / 2;
    final dy = size.height * (scale - 1) / 2;
    return Offset(offset.dx.clamp(-dx, dx), offset.dy.clamp(-dy, dy));
  }

  void _apply(double scale, Offset offset) {
    final wasZoomed = _zoomed;
    setState(() {
      _scale = scale.clamp(1, _maxScale);
      _offset = _scale <= 1.01 ? Offset.zero : _clamp(offset, _scale);
      if (_scale <= 1.01) _scale = 1;
    });
    if (wasZoomed != _zoomed) widget.onZoomChanged(_zoomed);
  }

  void _onDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length == 2) {
      _pinchStartDistance = _distance();
      _pinchStartScale = _scale;
    }
  }

  void _onMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length >= 2) {
      if (_pinchStartDistance > 0) {
        _apply(_pinchStartScale * _distance() / _pinchStartDistance, _offset);
      }
    } else if (_zoomed) {
      _apply(_scale, _offset + event.delta);
    }
  }

  void _onUp(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.length == 1) {
      // Al soltar un dedo del pellizco, el otro sigue moviendo la foto.
      _pinchStartDistance = 0;
    }
  }

  void _toggleZoom() =>
      _zoomed ? _apply(1, Offset.zero) : _apply(_doubleTapScale, Offset.zero);

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onUp,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: _toggleZoom,
        child: ClipRect(
          child: Transform(
            alignment: Alignment.center,
            transform:
                Matrix4.identity()
                  ..translateByDouble(_offset.dx, _offset.dy, 0, 1)
                  ..scaleByDouble(_scale, _scale, 1, 1),
            child: Center(
              child: Image.file(
                File(widget.path),
                fit: BoxFit.contain,
                semanticLabel: context.strings.coverLabel,
                errorBuilder:
                    (context, _, __) => Center(
                      child: Text(
                        context.strings.cannotPlay,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppOverlay.onVideo,
                        ),
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoPage extends StatefulWidget {
  const _VideoPage({required this.path, required this.active});

  final String path;
  final bool active;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path));
    _controller
        .initialize()
        .then((_) async {
          if (!mounted) return;
          await _controller.setLooping(true);
          if (widget.active) await _controller.play();
          if (mounted) setState(() => _ready = true);
        })
        .catchError((Object _) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  void didUpdateWidget(_VideoPage old) {
    super.didUpdateWidget(old);
    if (!_ready || old.active == widget.active) return;
    widget.active ? _controller.play() : _controller.pause();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!_ready) return;
    _controller.value.isPlaying ? _controller.pause() : _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
        child: Text(
          context.strings.cannotPlay,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppOverlay.onVideo),
        ),
      );
    }
    if (!_ready) {
      return const Center(
        child: CircularProgressIndicator(color: AppOverlay.onVideo),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
