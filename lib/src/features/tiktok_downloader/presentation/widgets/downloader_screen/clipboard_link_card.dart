import 'package:flutter/material.dart';

import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';

/// Ofrece el enlace de TikTok que el usuario acaba de copiar.
class ClipboardLinkCard extends StatelessWidget {
  const ClipboardLinkCard({super.key, required this.link, required this.onUse});

  final String link;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.content_paste_rounded, color: colors.downloading),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.strings.clipboardFound,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      link,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onUse,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSizes.touch),
              ),
              child: Text(context.strings.useThisLink),
            ),
          ),
        ],
      ),
    );
  }
}
