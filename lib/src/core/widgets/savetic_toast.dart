import 'package:flutter/material.dart';

import '../../config/theme/app_text.dart';
import '../../config/theme/app_tokens.dart';
import '../../config/theme/savetic_colors.dart';
import '../utils/app_enums.dart';

/// El aviso de SaveTic: una tarjeta con ícono de estado, el mensaje y, si hace
/// falta, una acción. Se dibuja con los colores del tema, igual que el resto.
class SaveticToast extends StatelessWidget {
  const SaveticToast({
    super.key,
    required this.message,
    required this.type,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final MessageType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Se llama cuando el usuario lo descarta, deslizándolo o con la acción.
  final VoidCallback onDismissed;

  Color _accent(SaveticColors colors) => switch (type) {
    MessageType.success => colors.done,
    MessageType.error => colors.failed,
    MessageType.info => colors.muted,
  };

  IconData get _icon => switch (type) {
    MessageType.success => Icons.check_rounded,
    MessageType.error => Icons.error_outline_rounded,
    MessageType.info => Icons.info_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final accent = _accent(colors);

    return SafeArea(
      bottom: false,
      minimum: const EdgeInsets.only(top: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.toastMaxWidth),
          child: Semantics(
            container: true,
            liveRegion: true,
            label: message,
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.up,
              onDismissed: (_) => onDismissed(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.raised,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: colors.line),
                  boxShadow: [
                    BoxShadow(
                      color: AppOverlay.shadeTop.withValues(alpha: 0.5),
                      blurRadius: AppSpacing.xl,
                      offset: const Offset(0, AppSpacing.sm),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: AppSizes.toastBadge,
                        height: AppSizes.toastBadge,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _icon,
                          size: AppSizes.iconMd + 2,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (actionLabel != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        TextButton(
                          onPressed: () {
                            onAction?.call();
                            onDismissed();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colors.accent,
                            textStyle: theme.textTheme.labelLarge?.tabular,
                          ),
                          child: Text(actionLabel!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
