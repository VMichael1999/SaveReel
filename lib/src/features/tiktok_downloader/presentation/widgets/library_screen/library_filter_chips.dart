import 'package:flutter/material.dart';

import '../../../../../config/theme/app_text.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../core/utils/app_strings.dart';

enum LibraryFilter { all, videos, audio }

/// Filtros de la biblioteca con la cantidad de cada uno.
class LibraryFilterChips extends StatelessWidget {
  const LibraryFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.counts,
  });

  final LibraryFilter selected;
  final ValueChanged<LibraryFilter> onSelected;
  final Map<LibraryFilter, int> counts;

  static const _labels = {
    LibraryFilter.all: AppStrings.libraryAll,
    LibraryFilter.videos: AppStrings.libraryVideos,
    LibraryFilter.audio: AppStrings.libraryAudio,
  };

  @override
  Widget build(BuildContext context) {
    final number = Theme.of(context).textTheme.labelMedium?.tabular;

    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final filter in LibraryFilter.values)
          ChoiceChip(
            label: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: _labels[filter]),
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
