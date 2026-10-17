import 'package:flutter/material.dart';

import '../../../../../config/theme/app_text.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../core/utils/app_strings.dart';

enum LibraryFilter { all, videos, audio, photos, favorites, tiktok, instagram }

/// Filtros de la biblioteca con la cantidad de cada uno.
class LibraryFilterChips extends StatelessWidget {
  const LibraryFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.counts,
    this.filters = const [
      LibraryFilter.all,
      LibraryFilter.videos,
      LibraryFilter.audio,
    ],
  });

  final LibraryFilter selected;
  final ValueChanged<LibraryFilter> onSelected;
  final Map<LibraryFilter, int> counts;

  /// Los filtros que se muestran; los de red solo cuando hay de ambas.
  final List<LibraryFilter> filters;

  static String _label(BuildContext context, LibraryFilter filter) =>
      switch (filter) {
        LibraryFilter.all => context.strings.libraryAll,
        LibraryFilter.videos => context.strings.libraryVideos,
        LibraryFilter.audio => context.strings.libraryAudio,
        LibraryFilter.photos => context.strings.libraryPhotos,
        LibraryFilter.favorites => context.strings.libraryFavorites,
        LibraryFilter.tiktok => 'TikTok',
        LibraryFilter.instagram => 'Instagram',
      };

  @override
  Widget build(BuildContext context) {
    final number = Theme.of(context).textTheme.labelMedium?.tabular;

    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final filter in filters)
          ChoiceChip(
            label: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: _label(context, filter)),
                  TextSpan(text: ' ${counts[filter] ?? 0}', style: number),
                ],
              ),
            ),
            selected: selected == filter,
            onSelected: (_) => onSelected(filter),
          ),
      ],
    );
  }
}
