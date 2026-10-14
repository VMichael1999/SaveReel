import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';
import '../../../../../core/utils/app_strings.dart';

/// Campo del enlace: un solo lugar para escribir, pegar y borrar.
class DownloaderBodyInputField extends StatelessWidget {
  const DownloaderBodyInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.onSubmit,
    required this.onPasted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final VoidCallback onSubmit;
  final VoidCallback onPasted;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    controller.text = text;
    onPasted();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    final colors = context.colors;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.go,
      autocorrect: false,
      enableSuggestions: false,
      onSubmitted: (_) => onSubmit(),
      decoration: InputDecoration(
        labelText: AppStrings.videoLink,
        hintText: AppStrings.inputLinkFieldText,
        errorText: errorText,
        errorMaxLines: 3,
        prefixIcon: Icon(
          Icons.link_rounded,
          color: errorText != null ? colors.failed : colors.muted,
        ),
        suffixIcon:
            hasText
                ? IconButton(
                  tooltip: AppStrings.clearField,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: controller.clear,
                )
                : Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: TextButton.icon(
                    onPressed: _paste,
                    icon: const Icon(
                      Icons.content_paste_rounded,
                      size: AppSpacing.lg,
                    ),
                    label: const Text(AppStrings.paste),
                  ),
                ),
      ),
    );
  }
}
