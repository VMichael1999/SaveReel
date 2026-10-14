import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_enums.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../bloc/downloader_bloc/downloader_bloc.dart';
import '../../bloc/library_cubit/library_cubit.dart';
import 'active_download_tile.dart';
import 'downloads_empty_state.dart';
import 'finished_download_tile.dart';
import 'library_link_row.dart';

class DownloadsScreenBody extends StatelessWidget {
  const DownloadsScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloaderBloc, DownloaderState>(
      builder: (context, _) {
        final bloc = context.read<DownloaderBloc>();
        final active =
            bloc.newDownloads
                .where((d) => d.status == DownloadStatus.downloading)
                .toList();
        final finished =
            bloc.newDownloads
                .where((d) => d.status != DownloadStatus.downloading)
                .toList()
                .reversed
                .toList();
        final hasLibrary =
            context.watch<LibraryCubit>().state.videos.isNotEmpty;

        if (active.isEmpty && finished.isEmpty && !hasLibrary) {
          return const DownloadsEmptyState();
        }

        // Las filas se construyen al desplazarse, no todas de golpe.
        final rows = <Widget Function()>[
          if (active.isNotEmpty) ...[
            () => const _SectionLabel(AppStrings.inProgress),
            for (final item in active)
              () => ActiveDownloadTile(key: ValueKey(item.path), item: item),
          ],
          if (finished.isNotEmpty) ...[
            () => const _SectionLabel(AppStrings.today),
            for (final item in finished)
              () => FinishedDownloadTile(key: ValueKey(item.path), item: item),
          ],
          () => const LibraryLinkRow(),
        ];

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          itemCount: rows.length,
          itemBuilder: (context, i) => rows[i](),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: context.colors.muted),
        ),
      ),
    );
  }
}
