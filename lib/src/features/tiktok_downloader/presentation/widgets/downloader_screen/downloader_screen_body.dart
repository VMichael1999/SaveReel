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
import '../download_bottom_sheet.dart';
import 'clipboard_link_card.dart';
import 'downloader_body_input_field.dart';
import 'recent_downloads_strip.dart';
import 'valid_links_hint.dart';

class DownloaderScreenBody extends StatefulWidget {
  const DownloaderScreenBody({super.key});

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
    context.read<DownloaderBloc>().add(LoadOldDownloads());
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
          buildDownloadBottomSheet(context, tikTokVideo);
        }
      case DownloaderSaveVideoSuccess(:final path):
        showAppMessage(
          context,
          msg: AppStrings.downloadSuccess,
          type: ToastType.success,
          actionLabel: AppStrings.play,
          onAction:
              () => Navigator.of(
                context,
              ).pushNamed(Routes.viewVideo, arguments: path),
        );
      case DownloaderSaveVideoFailure():
        showAppMessage(context, msg: state.message, type: ToastType.error);
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
                            dimension: AppSpacing.xl,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                          : const Icon(Icons.search_rounded),
                  label: Text(
                    searching ? AppStrings.searching : AppStrings.searchVideo,
                  ),
                ),
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
