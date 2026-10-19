import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/routes_manager.dart';
import '../../../../config/theme/app_tokens.dart';
import '../../../../core/helpers/app_launcher.dart';
import '../../../../core/layout/duo_context.dart';
import '../../../../core/layout/duo_layout.dart';
import '../../../../core/layout/duo_side_bar.dart';
import '../../../../core/layout/duo_split.dart';
import '../../../../core/utils/app_enums.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/savetic_mark.dart';
import '../bloc/downloader_bloc/downloader_bloc.dart';
import '../bloc/duo_pane_cubit/duo_pane_cubit.dart';
import '../widgets/downloader_screen/downloader_screen_app_bar.dart';
import '../widgets/downloader_screen/downloader_screen_body.dart';
import '../widgets/downloads_screen/downloads_screen_body.dart';
import '../widgets/video_preview/video_preview_sheet.dart';

class DownloaderScreen extends StatefulWidget {
  const DownloaderScreen({super.key, this.openTikTok = AppLauncher.openTikTok});

  /// Cómo se abre TikTok; las pruebas lo reemplazan.
  final Future<bool> Function() openTikTok;

  @override
  State<DownloaderScreen> createState() => _DownloaderScreenState();
}

class _DownloaderScreenState extends State<DownloaderScreen> {
  /// El cuerpo guarda el enlace escrito: la llave lo conserva al pasar de una
  /// pantalla a dos mitades y de vuelta.
  final GlobalKey _bodyKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final body = DownloaderScreenBody(
      key: _bodyKey,
      openTikTok: widget.openTikTok,
    );
    final layout = context.duoLayout;
    if (!context.hasDuoSideBar) {
      return Scaffold(appBar: const DownloaderScreenAppBar(), body: body);
    }

    // Con franja lateral, las acciones de la barra pasan a la franja y la
    // marca queda en el contenido.
    final home = MediaQuery.removePadding(
      context: context,
      removeRight: true,
      child: Column(
        children: [
          const _BrandHeader(),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: body,
            ),
          ),
        ],
      ),
    );

    if (layout == DuoLayout.openLandscape) {
      return Scaffold(
        body: DuoSplit(
          left: home,
          right: const _RightPane(),
          sideBar: const _HomeSideBar(),
        ),
      );
    }
    return Scaffold(
      body: Row(children: [Expanded(child: home), const _HomeSideBar()]),
    );
  }
}

/// La mitad derecha del inicio con el teléfono abierto: la vista previa del
/// video buscado o las descargas.
class _RightPane extends StatelessWidget {
  const _RightPane();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DuoPaneCubit, DuoPane>(
      builder: (context, pane) {
        final video = pane.video;
        if (video != null) {
          return SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: VideoPreviewPanel(
                key: ValueKey(video),
                video: video,
                initialFormat: pane.format,
                onFormatChanged: context.read<DuoPaneCubit>().setFormat,
                coverWidth: _previewCoverWidth,
              ),
            ),
          );
        }
        if (pane.downloads) {
          return SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(
                      context.strings.downloads,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                const Expanded(child: DownloadsScreenBody()),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Miniatura de la vista previa en la mitad derecha.
const double _previewCoverWidth = 132;

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          0,
        ),
        child: Row(
          children: [
            const SaveticMark(size: AppSizes.markBar),
            const SizedBox(width: AppSpacing.sm),
            Text(
              context.strings.appName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSideBar extends StatelessWidget {
  const _HomeSideBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloaderBloc, DownloaderState>(
      builder: (context, state) {
        final active =
            context
                .read<DownloaderBloc>()
                .newDownloads
                .where((d) => d.status == DownloadStatus.downloading)
                .length;

        return DuoSideBar(
          top: [
            DuoAction(
              icon: Icons.video_library_outlined,
              tooltip:
                  active > 0
                      ? context.strings.downloadsInProgress(active)
                      : context.strings.openDownloads,
              badgeCount: active,
              onPressed: () {
                if (context.duoLayout == DuoLayout.openLandscape) {
                  context.read<DuoPaneCubit>().showDownloads();
                } else {
                  Navigator.of(context).pushNamed(Routes.downloads);
                }
              },
            ),
            DuoAction(
              icon: Icons.settings_outlined,
              tooltip: context.strings.settingsOpen,
              onPressed: () => Navigator.of(context).pushNamed(Routes.settings),
            ),
          ],
        );
      },
    );
  }
}
