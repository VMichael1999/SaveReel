import 'package:flutter/material.dart';

/// Colores semánticos de SaveTic que `ColorScheme` no cubre.
@immutable
class SaveticColors extends ThemeExtension<SaveticColors> {
  const SaveticColors({
    required this.accent,
    required this.onAccent,
    required this.downloading,
    required this.done,
    required this.failed,
    required this.failedSoft,
    required this.raised,
    required this.line,
    required this.border,
    required this.muted,
    required this.scrim,
  });

  /// Color de la acción principal.
  final Color accent;
  final Color onAccent;

  /// Progreso de una descarga en curso.
  final Color downloading;

  /// Descarga terminada.
  final Color done;

  /// Descarga fallida y su fondo suave.
  final Color failed;
  final Color failedSoft;

  /// Superficie elevada sobre la superficie normal.
  final Color raised;

  /// Divisores y bordes finos.
  final Color line;

  /// Contorno de los controles (campos, botones con borde, filtros): llega
  /// a 3:1 contra el fondo para que se distingan.
  final Color border;

  /// Texto secundario.
  final Color muted;

  /// Capa oscura detrás de las hojas.
  final Color scrim;

  static const SaveticColors dark = SaveticColors(
    accent: Color(0xFFFF4D8D),
    onAccent: Color(0xFF1A0B1F),
    downloading: Color(0xFF25F4EE),
    done: Color(0xFF4DF0D8),
    failed: Color(0xFFFF7A59),
    failedSoft: Color(0xFF3A1A22),
    raised: Color(0xFF211A42),
    line: Color(0xFF2C2354),
    border: Color(0xFF6B5F9E),
    muted: Color(0xFFA59CC4),
    scrim: Color(0x9E07041A),
  );

  static const SaveticColors light = SaveticColors(
    accent: Color(0xFFD81B60),
    onAccent: Color(0xFFFFFFFF),
    downloading: Color(0xFF0A7F85),
    done: Color(0xFF0B7A6E),
    failed: Color(0xFFC2410C),
    failedSoft: Color(0xFFFDEBE3),
    raised: Color(0xFFF1ECFA),
    line: Color(0xFFE4DCF2),
    border: Color(0xFF8A7FB0),
    muted: Color(0xFF5E5580),
    scrim: Color(0x9E07041A),
  );

  /// Violeta → magenta → naranja: el barrido de Instagram sobre el rosa de
  /// TikTok. Solo decora (logo, insignias, progreso); nunca lleva texto.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF8134AF), Color(0xFFFF4D8D), Color(0xFFFF9A3C)],
  );

  @override
  SaveticColors copyWith({
    Color? accent,
    Color? onAccent,
    Color? downloading,
    Color? done,
    Color? failed,
    Color? failedSoft,
    Color? raised,
    Color? line,
    Color? border,
    Color? muted,
    Color? scrim,
  }) {
    return SaveticColors(
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      downloading: downloading ?? this.downloading,
      done: done ?? this.done,
      failed: failed ?? this.failed,
      failedSoft: failedSoft ?? this.failedSoft,
      raised: raised ?? this.raised,
      line: line ?? this.line,
      border: border ?? this.border,
      muted: muted ?? this.muted,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  SaveticColors lerp(ThemeExtension<SaveticColors>? other, double t) {
    if (other is! SaveticColors) return this;
    return SaveticColors(
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      downloading: Color.lerp(downloading, other.downloading, t)!,
      done: Color.lerp(done, other.done, t)!,
      failed: Color.lerp(failed, other.failed, t)!,
      failedSoft: Color.lerp(failedSoft, other.failedSoft, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      line: Color.lerp(line, other.line, t)!,
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

extension SaveticThemeContext on BuildContext {
  SaveticColors get colors => Theme.of(this).extension<SaveticColors>()!;
}
