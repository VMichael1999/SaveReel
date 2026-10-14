import 'package:flutter/material.dart';

import '../../../../../config/theme/app_text.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';

/// Una opción de formato dentro de la vista previa, con forma de botón de radio.
class FormatOption extends StatelessWidget {
  const FormatOption({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
    this.size,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

  /// Peso del archivo ya formateado, si se conoce.
  final String? size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final enabled = onTap != null;
    final borderColor = selected ? colors.accent : colors.border;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      label: [
        title,
        if (subtitle != null) subtitle!,
        if (size != null) size!,
      ].join('. '),
      excludeSemantics: true,
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: selected ? colors.raised : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSizes.touch),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: borderColor,
                  width: AppSizes.borderThin,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? colors.accent : colors.muted,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.labelLarge),
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
                  if (size != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      size!,
                      style: theme.textTheme.labelMedium?.tabular.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
