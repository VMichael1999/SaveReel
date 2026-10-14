import 'package:flutter/material.dart';

import '../../../../../config/theme/app_tokens.dart';
import '../../../../../core/utils/app_strings.dart';

/// Muestra cómo se ve un enlace que sí funciona.
class ValidLinksHint extends StatelessWidget {
  const ValidLinksHint({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      color: theme.colorScheme.onSurface,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.validLinksLook, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Text('vm.tiktok.com/ZMh7K2pQx/', style: mono),
          const SizedBox(height: AppSpacing.xs),
          Text('tiktok.com/@autor/video/7412…', style: mono),
        ],
      ),
    );
  }
}
