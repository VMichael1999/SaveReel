import 'package:flutter/material.dart';

import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';

/// Lo que se ve cuando todavía no hay nada guardado.
class DownloadsEmptyState extends StatelessWidget {
  const DownloadsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: AppSizes.touch,
              color: context.colors.muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.strings.emptyDownloadsTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.strings.emptyDownloadsBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.colors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(context.strings.pasteALink),
            ),
          ],
        ),
      ),
    );
  }
}
