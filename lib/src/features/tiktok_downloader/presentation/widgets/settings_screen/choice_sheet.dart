import 'package:flutter/material.dart';

import '../../../../../config/theme/app_tokens.dart';
import '../video_preview/format_option.dart';

class ChoiceOption<T> {
  const ChoiceOption({required this.value, required this.title, this.subtitle});

  final T value;
  final String title;
  final String? subtitle;
}

/// Hoja para elegir una opción entre varias. Devuelve la elegida, o nulo
/// si se cierra sin elegir.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<ChoiceOption<T>> options,
  required T selected,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle:
        reduceMotion
            ? AnimationStyle.noAnimation
            : AnimationStyle(
              duration: AppMotion.sheet,
              curve: AppMotion.emphasized,
              reverseDuration: AppMotion.base,
              reverseCurve: AppMotion.exit,
            ),
    builder:
        (context) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final option in options) ...[
                FormatOption(
                  title: option.title,
                  subtitle: option.subtitle,
                  selected: option.value == selected,
                  onTap: () => Navigator.of(context).pop(option.value),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
  );
}
