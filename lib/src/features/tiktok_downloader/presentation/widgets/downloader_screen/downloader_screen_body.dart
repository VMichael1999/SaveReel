import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../core/utils/app_enums.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/utils/video_link.dart';
import '../../../../../core/widgets/app_message.dart';
import '../../../../../core/widgets/motion.dart';
import '../../bloc/downloader_bloc/downloader_bloc.dart';
import '../../bloc/first_use_cubit/first_use_cubit.dart';
import '../../bloc/library_cubit/library_cubit.dart';
import '../video_preview/video_preview_sheet.dart';
import '../video_preview/video_preview_skeleton.dart';
import 'clipboard_link_card.dart';
import 'downloader_body_input_field.dart';
import 'first_use_view.dart';
import 'recent_downloads_strip.dart';
import 'valid_links_hint.dart';

class DownloaderScreenBody extends StatefulWidget {
  const DownloaderScreenBody({super.key, required this.openTikTok});

  final Future<bool> Function() openTikTok;

  @override
  State<DownloaderScreenBody> createState() => _DownloaderScreenBodyState();
}

class _DownloaderScreenBodyState extends State<DownloaderScreenBody>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Enlace de TikTok encontrado en el portapapeles, si lo hay.
  String? _clipboardLink;

  /// Enlace del portapapeles que el usuario ya usó o ignoró.
  String? _handledLink;

  /// Se muestra el error del enlace solo cuando el usuario ya terminó de
  /// escribir o pegó algo, para no regañarlo a mitad de camino.
  bool _touched = false;

  /// Aviso de la guía cuando TikTok no se pudo abrir.
  String? _firstUseError;

  /// Error devuelto por el servicio al buscar el video.
  String? _serviceError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _controller.text.isNotEmpty) {
        setState(() => _touched = true);
      }
    });
    _checkClipboard();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() => _serviceError = null);
  }

  Future<void> _checkClipboard() async {
    if (!await Clipboard.hasStrings()) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final link = VideoLink.find(data?.text ?? '');
    if (!mounted || link == null) return;
    if (link == _handledLink || link == _controller.text.trim()) return;
    setState(() => _clipboardLink = link);
  }

  void _useClipboardLink() {
    final link = _clipboardLink;
    if (link == null) return;
    _controller.text = link;
    setState(() {
      _handledLink = link;
      _clipboardLink = null;
      _touched = true;
    });
  }

  Future<void> _openTikTok() async {
    setState(() => _firstUseError = null);
    final opened = await widget.openTikTok();
    if (!opened && mounted) {
      setState(() => _firstUseError = AppStrings.tikTokNotFound);
    }
  }

  /// La guía solo aparece a quien aún no ha guardado nada y no trae un
  /// enlace a la mano.
  bool _showFirstUse(BuildContext context) {
    final firstUse = context.watch<FirstUseCubit>().state;
    final library = context.watch<LibraryCubit>().state;
    final hasSessionDownloads =
        context.read<DownloaderBloc>().newDownloads.isNotEmpty;
    return firstUse.loaded &&
        !firstUse.dismissed &&
        library.status == LibraryStatus.ready &&
        library.videos.isEmpty &&
        !hasSessionDownloads &&
        _clipboardLink == null &&
        _controller.text.isEmpty;
  }

  VideoLinkCheck get _check => VideoLink.check(_controller.text);

  String? get _errorText {
    if (_serviceError != null) return _serviceError;
    final check = _check;
    final immediate =
        check.status == VideoLinkStatus.otherPlatform ||
        check.status == VideoLinkStatus.notAVideo;
    if (!_touched && !immediate) return null;
    return switch (check.status) {
      VideoLinkStatus.empty || VideoLinkStatus.valid => null,
      VideoLinkStatus.notAVideo => AppStrings.linkNotAVideo,
      VideoLinkStatus.otherPlatform => AppStrings.linkOtherPlatform(
        check.platform!,
      ),
      VideoLinkStatus.notTikTok => AppStrings.linkNotTikTok,
    };
  }

  void _search() {
    if (!_check.isValid) {
      setState(() => _touched = true);
      return;
    }
    _focusNode.unfocus();
    context.read<FirstUseCubit>().dismiss();
    context.read<DownloaderBloc>().add(
      DownloaderGetVideo(_controller.text.trim()),
    );
  }

  void _onBlocState(BuildContext context, DownloaderState state) {
    switch (state) {
      case DownloaderSaveVideoLoading():
        Navigator.of(context).popAndPushNamed(Routes.downloads);
      case DownloaderGetVideoFailure():
        setState(() => _serviceError = state.message);
      case DownloaderGetVideoSuccess(:final tikTokVideo):
        if (tikTokVideo.videoData == null) {
          setState(() => _serviceError = AppStrings.videoUnavailable);
        } else {
          showVideoPreviewSheet(context, tikTokVideo);
        }
      case DownloaderSaveVideoSuccess(:final path):
        showAppMessage(
          context,
          msg: AppStrings.downloadSuccess,
          type: MessageType.success,
          actionLabel: AppStrings.play,
          onAction:
              () => Navigator.of(context).pushNamed(
                Routes.viewVideo,
                arguments: context.read<DownloaderBloc>().playerArgsFor(path),
              ),
        );
      case DownloaderVideoDeleted():
        showAppMessage(
          context,
          msg: AppStrings.videoDeleted,
          type: MessageType.success,
        );
      case DownloaderSaveVideoCancelled():
        showAppMessage(
          context,
          msg: AppStrings.downloadCancelled,
          type: MessageType.success,
        );
      case DownloaderSaveVideoFailure():
        showAppMessage(context, msg: state.message, type: MessageType.error);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<DownloaderBloc, DownloaderState>(
      listener: _onBlocState,
      builder: (context, state) {
        if (_showFirstUse(context)) {
          return FirstUseView(
            onOpenTikTok: _openTikTok,
            errorText: _firstUseError,
            onHaveLink: () => context.read<FirstUseCubit>().dismiss(),
          );
        }
        final searching = state is DownloaderGetVideoLoading;
        final canSearch = _check.isValid && !searching;
        final errorText = _errorText;

        return SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.homeTitle,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_clipboardLink != null) ...[
                  ClipboardLinkCard(
                    link: _clipboardLink!,
                    onUse: _useClipboardLink,
                  ).enter(context),
                  const SizedBox(height: AppSpacing.lg),
                ],
                ListenableBuilder(
                  listenable: _controller,
                  builder:
                      (context, _) => DownloaderBodyInputField(
                        controller: _controller,
                        focusNode: _focusNode,
                        errorText: errorText,
                        onSubmit: _search,
                        onPasted: () => setState(() => _touched = true),
                      ),
                ),
                if (errorText != null &&
                    _check.status == VideoLinkStatus.notTikTok) ...[
                  const SizedBox(height: AppSpacing.md),
                  const ValidLinksHint().enter(context),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: canSearch ? _search : null,
                  icon:
                      searching
                          ? const SizedBox.square(
                            dimension: AppSizes.loader,
                            child: CircularProgressIndicator(
                              strokeWidth: AppSizes.loaderStroke,
                            ),
                          )
                          : const Icon(Icons.search_rounded),
                  label: Text(
                    searching ? AppStrings.searching : AppStrings.searchVideo,
                  ),
                ),
                if (searching) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const VideoPreviewSkeleton(),
                ],
                const SizedBox(height: AppSpacing.xl),
                const RecentDownloadsStrip(),
              ],
            ),
          ),
        );
      },
    );
  }
}
