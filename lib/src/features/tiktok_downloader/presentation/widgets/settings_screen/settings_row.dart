import 'package:flutter/material.dart';

import '../../../../../config/theme/app_text.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';

/// Una fila de ajustes: ícono, título, detalle y, a la derecha, su valor.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.showChevron = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Valor actual, por ejemplo «Oscuro».
  final String? value;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Semantics(
      button: onTap != null,
      container: true,
      label: [
        title,
        if (subtitle != null) subtitle!,
        if (value != null) value!,
      ].join(', '),
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.touch + 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(icon, color: colors.muted),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.bodyLarge),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    value!,
                    style: theme.textTheme.labelMedium?.tabular.copyWith(
                      color: colors.muted,
                    ),
                  ),
                ],
                if (showChevron)
                  Icon(Icons.chevron_right_rounded, color: colors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
