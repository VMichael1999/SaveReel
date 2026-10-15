import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_tokens.dart';
import '../../../../config/theme/savetic_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/video_link.dart';
import '../../domain/entities/saved_video.dart';
import '../bloc/library_cubit/library_cubit.dart';
import '../widgets/downloads_screen/downloads_empty_state.dart';
import '../widgets/library_screen/library_filter_chips.dart';
import '../widgets/library_screen/library_tile.dart';

/// Todos los videos y audios guardados, en una cuadrícula vertical.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryFilter _filter = LibraryFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<LibraryCubit>().load();
  }

  List<SavedVideo> _apply(List<SavedVideo> all) => switch (_filter) {
    LibraryFilter.all => all,
    LibraryFilter.videos => all.where((v) => !v.isAudio).toList(),
    LibraryFilter.audio => all.where((v) => v.isAudio).toList(),
    LibraryFilter.tiktok =>
      all.where((v) => v.source == VideoNetwork.tiktok).toList(),
    LibraryFilter.instagram =>
      all.where((v) => v.source == VideoNetwork.instagram).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          if (state.status == LibraryStatus.ready && state.videos.isEmpty) {
            return const DownloadsEmptyState();
          }
          final videos = _apply(state.videos);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList.list(
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        AppStrings.libraryTitle,
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppStrings.filesSummary(
                        state.videos.length,
                        formatMegabytes(state.totalBytes),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.colors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    LibraryFilterChips(
                      selected: _filter,
                      onSelected: (f) => setState(() => _filter = f),
                      counts: {
                        LibraryFilter.all: state.videos.length,
                        LibraryFilter.videos: state.videoCount,
                        LibraryFilter.audio: state.audioCount,
                        LibraryFilter.tiktok: state.countOf(VideoNetwork.tiktok),
                        LibraryFilter.instagram: state.countOf(
                          VideoNetwork.instagram,
                        ),
                      },
                      filters: [
                        LibraryFilter.all,
                        LibraryFilter.videos,
                        LibraryFilter.audio,
                        if (state.countOf(VideoNetwork.tiktok) > 0 &&
                            state.countOf(VideoNetwork.instagram) > 0) ...[
                          LibraryFilter.tiktok,
                          LibraryFilter.instagram,
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
              if (state.status == LibraryStatus.loading)
                const _GridSkeleton()
              else if (videos.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      AppStrings.libraryFilterEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.colors.muted,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 9 / 16,
                        ),
                    itemCount: videos.length,
                    itemBuilder:
                        (context, i) => LibraryTile(
                          key: ValueKey(videos[i].path),
                          video: videos[i],
                        ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Mientras carga: cuadros con la forma de las miniaturas.
class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 9 / 16,
        ),
        itemCount: 6,
        itemBuilder:
            (context, _) => DecoratedBox(
              decoration: BoxDecoration(
                color: colors.line,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
            ),
      ),
    );
  }
}
