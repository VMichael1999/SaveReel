import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_tokens.dart';
import '../../../../config/theme/savetic_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/text_search.dart';
import '../../../../core/utils/video_link.dart';
import '../../domain/entities/saved_video.dart';
import '../bloc/downloader_bloc/downloader_bloc.dart';
import '../bloc/library_cubit/library_cubit.dart';
import '../models/library_sort.dart';
import '../widgets/downloads_screen/downloads_empty_state.dart';
import '../widgets/library_screen/library_bulk_actions.dart';
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
  LibrarySort _sort = LibrarySort.newest;
  final TextEditingController _query = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _searching = false;

  /// Rutas elegidas en el modo selección; `null` fuera de él.
  Set<String>? _selected;

  bool get _selecting => _selected != null;

  @override
  void initState() {
    super.initState();
    context.read<LibraryCubit>().load();
  }

  @override
  void dispose() {
    _query.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _startSelecting([String? first]) => setState(() {
    _searching = false;
    _selected = {if (first != null) first};
  });

  void _stopSelecting() => setState(() => _selected = null);

  void _toggle(String path) {
    final selected = _selected;
    if (selected == null) return;
    HapticFeedback.selectionClick().catchError((_) {});
    setState(() {
      selected.contains(path) ? selected.remove(path) : selected.add(path);
    });
  }

  void _openSearch() => setState(() {
    _searching = true;
    _selected = null;
  });

  void _closeSearch() => setState(() {
    _searching = false;
    _query.clear();
  });

  /// Lo elegido que todavía existe en la biblioteca.
  List<SavedVideo> _chosen(List<SavedVideo> all) => [
    for (final video in all)
      if (_selected?.contains(video.path) ?? false) video,
  ];

  Future<void> _deleteChosen(List<SavedVideo> chosen) async {
    final bloc = context.read<DownloaderBloc>();
    final confirmed = await confirmDeleteMany(context, chosen.length);
    if (!confirmed || !mounted) return;
    for (final video in chosen) {
      bloc.add(DownloaderDeleteVideo(video.path));
    }
    _stopSelecting();
  }

  List<SavedVideo> _visible(List<SavedVideo> all) {
    final byFilter = _apply(all);
    final query = _query.text;
    final matching =
        query.trim().isEmpty
            ? byFilter
            : byFilter
                .where(
                  (v) => TextSearch.matches(
                    '${v.title ?? ''} ${v.authorHandle ?? ''}',
                    query,
                  ),
                )
                .toList();
    return _sort.apply(matching);
  }

  String _sortName(LibrarySort sort) => switch (sort) {
    LibrarySort.newest => context.strings.sortNewest,
    LibrarySort.oldest => context.strings.sortOldest,
    LibrarySort.biggest => context.strings.sortBiggest,
    LibrarySort.title => context.strings.sortTitle,
  };

  AppBar _appBar(List<SavedVideo> all, List<SavedVideo> visible) {
    if (_selecting) {
      return AppBar(
        leading: IconButton(
          tooltip: context.strings.cancelSelection,
          icon: const Icon(Icons.close_rounded),
          onPressed: _stopSelecting,
        ),
        title: Text(context.strings.selectedCount(_chosen(all).length)),
        actions: [
          IconButton(
            tooltip: context.strings.selectAll,
            icon: const Icon(Icons.select_all_rounded),
            onPressed:
                () => setState(() {
                  _selected = {for (final v in visible) v.path};
                }),
          ),
        ],
      );
    }
    if (_searching) {
      return AppBar(
        leading: IconButton(
          tooltip: context.strings.closeSearch,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _closeSearch,
        ),
        title: TextField(
          controller: _query,
          focusNode: _searchFocus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: Theme.of(context).textTheme.titleMedium,
          // Sin borde ni relleno: el tema los pone a todos los campos.
          decoration: InputDecoration(
            hintText: context.strings.searchHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          if (_query.text.isNotEmpty)
            IconButton(
              tooltip: context.strings.clearSearch,
              icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(_query.clear),
            ),
        ],
      );
    }
    return AppBar(
      actions: [
        IconButton(
          tooltip: context.strings.search,
          icon: const Icon(Icons.search_rounded),
          onPressed: _openSearch,
        ),
        PopupMenuButton<LibrarySort>(
          tooltip: context.strings.sort,
          icon: const Icon(Icons.sort_rounded),
          initialValue: _sort,
          onSelected: (sort) => setState(() => _sort = sort),
          itemBuilder:
              (context) => [
                for (final sort in LibrarySort.values)
                  CheckedPopupMenuItem(
                    value: sort,
                    checked: sort == _sort,
                    child: Text(_sortName(sort)),
                  ),
              ],
        ),
        IconButton(
          tooltip: context.strings.select,
          icon: const Icon(Icons.checklist_rounded),
          onPressed: _startSelecting,
        ),
      ],
    );
  }

  Widget? _selectionBar(List<SavedVideo> all) {
    if (!_selecting) return null;
    final chosen = _chosen(all);
    final enabled = chosen.isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: _BarAction(
                icon: Icons.ios_share_rounded,
                label: context.strings.share,
                onTap: enabled ? () => shareSavedVideos(chosen) : null,
              ),
            ),
            Expanded(
              child: _BarAction(
                icon: Icons.photo_library_outlined,
                label: context.strings.galleryShort,
                onTap:
                    enabled && chosen.any((v) => !v.isAudio)
                        ? () => saveSavedVideosToGallery(context, chosen)
                        : null,
              ),
            ),
            Expanded(
              child: _BarAction(
                icon: Icons.delete_outline_rounded,
                label: context.strings.delete,
                color: context.colors.failed,
                onTap: enabled ? () => _deleteChosen(chosen) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SavedVideo> _apply(List<SavedVideo> all) => switch (_filter) {
    LibraryFilter.all => all,
    LibraryFilter.videos =>
      all.where((v) => !v.isAudio && !v.isGallery).toList(),
    LibraryFilter.photos => all.where((v) => v.isGallery).toList(),
    LibraryFilter.audio => all.where((v) => v.isAudio).toList(),
    LibraryFilter.tiktok =>
      all.where((v) => v.source == VideoNetwork.tiktok).toList(),
    LibraryFilter.instagram =>
      all.where((v) => v.source == VideoNetwork.instagram).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final videos = _visible(state.videos);
        // Un elemento borrado sale también de la selección.
        _selected?.retainAll({for (final v in state.videos) v.path});

        return PopScope(
          canPop: !_selecting && !_searching,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _selecting ? _stopSelecting() : _closeSearch();
          },
          child: Scaffold(
            appBar: _appBar(state.videos, videos),
            bottomNavigationBar: _selectionBar(state.videos),
            body: _body(context, state, videos, theme),
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    LibraryState state,
    List<SavedVideo> videos,
    ThemeData theme,
  ) {
    if (state.status == LibraryStatus.ready && state.videos.isEmpty) {
      return const DownloadsEmptyState();
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList.list(
            children: [
              Semantics(
                header: true,
                child: Text(
                  context.strings.libraryTitle,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.strings.filesSummary(
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
                  LibraryFilter.photos: state.galleryCount,
                  LibraryFilter.tiktok: state.countOf(VideoNetwork.tiktok),
                  LibraryFilter.instagram: state.countOf(
                    VideoNetwork.instagram,
                  ),
                },
                filters: [
                  LibraryFilter.all,
                  LibraryFilter.videos,
                  LibraryFilter.audio,
                  if (state.galleryCount > 0) LibraryFilter.photos,
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
                _query.text.trim().isEmpty
                    ? context.strings.libraryFilterEmpty
                    : context.strings.noMatches(_query.text.trim()),
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                    selecting: _selecting,
                    selected: _selected?.contains(videos[i].path) ?? false,
                    onToggle: () => _toggle(videos[i].path),
                    onStartSelecting: () => _startSelecting(videos[i].path),
                  ),
            ),
          ),
      ],
    );
  }
}

/// Un botón de la barra de selección: ícono con su texto debajo.
class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = color ?? theme.colorScheme.onSurface;
    final tint = onTap == null ? base.withValues(alpha: 0.38) : base;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.touch + 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Icon(icon, color: tint),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: tint),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
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
