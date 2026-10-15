import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../core/utils/app_enums.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/widgets/savetic_mark.dart';
import '../../bloc/downloader_bloc/downloader_bloc.dart';

class DownloaderScreenAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const DownloaderScreenAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      centerTitle: false,
      titleSpacing: AppSpacing.lg,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SaveticMark(size: AppSizes.markBar),
          const SizedBox(width: AppSpacing.sm),
          Text(context.strings.appName, style: theme.textTheme.titleLarge),
        ],
      ),
      actions: [
        BlocBuilder<DownloaderBloc, DownloaderState>(
          builder: (context, state) {
            final active =
                context
                    .read<DownloaderBloc>()
                    .newDownloads
                    .where((d) => d.status == DownloadStatus.downloading)
                    .length;

            return IconButton(
              tooltip:
                  active > 0
                      ? context.strings.downloadsInProgress(active)
                      : context.strings.openDownloads,
              onPressed:
                  () => Navigator.of(context).pushNamed(Routes.downloads),
              icon: Badge(
                isLabelVisible: active > 0,
                label: Text('$active'),
                child: const Icon(Icons.video_library_outlined),
              ),
            );
          },
        ),
        IconButton(
          tooltip: context.strings.settingsOpen,
          onPressed: () => Navigator.of(context).pushNamed(Routes.settings),
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
