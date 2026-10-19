import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/routes_manager.dart';
import '../../../../config/theme/app_tokens.dart';
import '../../../../core/helpers/app_launcher.dart';
import '../../../../core/layout/duo_context.dart';
import '../../../../core/layout/duo_side_bar.dart';
import '../../../../core/utils/app_enums.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/savetic_mark.dart';
import '../bloc/downloader_bloc/downloader_bloc.dart';
import '../widgets/downloader_screen/downloader_screen_app_bar.dart';
import '../widgets/downloader_screen/downloader_screen_body.dart';

class DownloaderScreen extends StatelessWidget {
  const DownloaderScreen({super.key, this.openTikTok = AppLauncher.openTikTok});

  /// Cómo se abre TikTok; las pruebas lo reemplazan.
  final Future<bool> Function() openTikTok;

  @override
  Widget build(BuildContext context) {
    final body = DownloaderScreenBody(openTikTok: openTikTok);
    if (!context.hasDuoSideBar) {
      return Scaffold(appBar: const DownloaderScreenAppBar(), body: body);
    }

    // Con franja lateral, las acciones de la barra pasan a la franja y la
    // marca queda en el contenido.
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: MediaQuery.removePadding(
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
            ),
          ),
          const _HomeSideBar(),
        ],
      ),
    );
  }
}

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
              onPressed:
                  () => Navigator.of(context).pushNamed(Routes.downloads),
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
