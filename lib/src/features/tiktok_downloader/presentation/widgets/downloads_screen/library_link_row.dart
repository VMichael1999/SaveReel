import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/utils/formatters.dart';
import '../../bloc/library_cubit/library_cubit.dart';

/// Acceso a la biblioteca desde la pantalla de descargas.
class LibraryLinkRow extends StatelessWidget {
  const LibraryLinkRow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<LibraryCubit>().state;
    if (state.videos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () => Navigator.of(context).pushNamed(Routes.library),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(Icons.video_library_outlined, color: context.colors.muted),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.strings.openLibrary,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        context.strings.filesSummary(
                          state.videos.length,
                          formatMegabytes(state.totalBytes),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.colors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.colors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
