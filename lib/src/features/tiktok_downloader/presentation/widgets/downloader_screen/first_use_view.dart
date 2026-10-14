import 'package:flutter/material.dart';

import '../../../../../config/theme/app_text.dart';
import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';

/// Guía para quien aún no ha guardado nada: una secuencia real de tres pasos,
/// así que los números sí tienen sentido.
class FirstUseView extends StatelessWidget {
  const FirstUseView({
    super.key,
    required this.onOpenTikTok,
    required this.onHaveLink,
    this.errorText,
  });

  final VoidCallback onOpenTikTok;
  final VoidCallback onHaveLink;

  /// Aviso dentro de la pantalla, por ejemplo si TikTok no está instalado.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      AppStrings.firstUseTitle,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _Step(
                    number: 1,
                    title: AppStrings.step1Title,
                    body: AppStrings.step1Body,
                  ),
                  const Divider(),
                  const _Step(
                    number: 2,
                    title: AppStrings.step2Title,
                    body: AppStrings.step2Body,
                  ),
                  const Divider(),
                  const _Step(
                    number: 3,
                    title: AppStrings.step3Title,
                    body: AppStrings.step3Body,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Icon(
                          Icons.photo_library_outlined,
                          size: AppSizes.iconSm,
                          color: colors.muted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.muted,
                            ),
                            children: [
                              const TextSpan(text: AppStrings.galleryTipLead),
                              TextSpan(
                                text: AppStrings.galleryTipBold,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(text: AppStrings.galleryTipTail),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (errorText != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: AppSizes.iconSm,
                        color: colors.failed,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          errorText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.failed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                FilledButton(
                  onPressed: onOpenTikTok,
                  child: const Text(AppStrings.openTikTok),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: onHaveLink,
                  child: const Text(AppStrings.haveALink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.body});

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Semantics(
      container: true,
      label: AppStrings.stepLabel(number, title),
      value: body,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppSizes.stepBadge,
              height: AppSizes.stepBadge,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.line,
                  width: AppSizes.borderThin,
                ),
              ),
              child: Text(
                '$number',
                style: theme.textTheme.labelLarge?.tabular,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
