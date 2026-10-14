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

  /// Texto secundario.
  final Color muted;

  /// Capa oscura detrás de las hojas.
  final Color scrim;

  static const SaveticColors dark = SaveticColors(
    accent: Color(0xFF99F2C8),
    onAccent: Color(0xFF06152D),
    downloading: Color(0xFF99F2C8),
    done: Color(0xFF99F2C8),
    failed: Color(0xFFFF7A7A),
    failedSoft: Color(0xFF3A1A24),
    raised: Color(0xFF13294D),
    line: Color(0xFF1C3356),
    muted: Color(0xFF93A3B8),
    scrim: Color(0x9E020812),
  );

  static const SaveticColors light = SaveticColors(
    accent: Color(0xFF06152D),
    onAccent: Color(0xFFFFFFFF),
    downloading: Color(0xFF0B7A55),
    done: Color(0xFF0B7A55),
    failed: Color(0xFFC62828),
    failedSoft: Color(0xFFFCE4E4),
    raised: Color(0xFFEEF1F5),
    line: Color(0xFFE1E6ED),
    muted: Color(0xFF53627A),
    scrim: Color(0x9E020812),
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
      muted: Color.lerp(muted, other.muted, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

extension SaveticThemeContext on BuildContext {
  SaveticColors get colors => Theme.of(this).extension<SaveticColors>()!;
}
