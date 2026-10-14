import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_enums.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../bloc/downloader_bloc/downloader_bloc.dart';
import 'active_download_tile.dart';
import 'downloads_empty_state.dart';
import 'finished_download_tile.dart';
import 'saved_video_tile.dart';

class DownloadsScreenBody extends StatefulWidget {
  const DownloadsScreenBody({super.key});

  @override
  State<DownloadsScreenBody> createState() => _DownloadsScreenBodyState();
}

class _DownloadsScreenBodyState extends State<DownloadsScreenBody> {
  @override
  void initState() {
    super.initState();
    context.read<DownloaderBloc>().add(LoadOldDownloads());
  }

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
        final earlier = bloc.oldDownloads;

        if (active.isEmpty && finished.isEmpty && earlier.isEmpty) {
          return const DownloadsEmptyState();
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            if (active.isNotEmpty) ...[
              const _SectionLabel(AppStrings.inProgress),
              for (final item in active)
                ActiveDownloadTile(key: ValueKey(item.path), item: item),
            ],
            if (finished.isNotEmpty) ...[
              const _SectionLabel(AppStrings.today),
              for (final item in finished)
                FinishedDownloadTile(key: ValueKey(item.path), item: item),
            ],
            if (earlier.isNotEmpty) ...[
              const _SectionLabel(AppStrings.savedBefore),
              for (final video in earlier)
                SavedVideoTile(key: ValueKey(video.path), video: video),
            ],
          ],
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
