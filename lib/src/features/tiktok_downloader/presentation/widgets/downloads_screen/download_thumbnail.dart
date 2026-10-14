import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../config/theme/app_tokens.dart';
import '../../../../../config/theme/savetic_colors.dart';

/// Miniatura vertical de un video, de una portada en línea o de un archivo.
class DownloadThumbnail extends StatelessWidget {
  const DownloadThumbnail.network(String this.url, {super.key, this.icon})
    : filePath = null;

  const DownloadThumbnail.file(String this.filePath, {super.key, this.icon})
    : url = null;

  static const double width = 52;

  final String? url;
  final String? filePath;

  /// Ícono de relleno cuando no hay imagen, por ejemplo para un audio.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final placeholder = ColoredBox(
      color: colors.raised,
      child: Icon(icon ?? Icons.movie_outlined, color: colors.muted),
    );

    final Widget image;
    if (url != null && url!.isNotEmpty) {
      image = Image.network(
        url!,
        fit: BoxFit.cover,
        cacheWidth: 160,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else if (filePath != null && File(filePath!).existsSync()) {
      image = Image.file(
        File(filePath!),
        fit: BoxFit.cover,
        cacheWidth: 160,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else {
      image = placeholder;
    }

    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: AspectRatio(aspectRatio: 9 / 16, child: image),
      ),
    );
  }
}
