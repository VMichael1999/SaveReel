import 'package:flutter/material.dart';

/// Escala de texto de SaveTic, sobre la fuente del sistema
/// (Roboto en Android, San Francisco en iOS). Sin colores: los pone el tema.
abstract final class AppText {
  static const TextTheme scale = TextTheme(
    // Título de pantalla: «Pega el enlace del video».
    headlineMedium: TextStyle(
      fontSize: 27,
      height: 1.12,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.54,
    ),
    // Título de sección o de hoja.
    titleLarge: TextStyle(
      fontSize: 17,
      height: 1.25,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.17,
    ),
    // Título de un elemento: nombre del video, ajuste.
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.25,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      height: 1.4,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.w400,
    ),
    // Detalle: autor, estado, ayuda.
    bodySmall: TextStyle(
      fontSize: 12.5,
      height: 1.4,
      fontWeight: FontWeight.w400,
    ),
    // Texto de botón.
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    // Etiquetas de sección y chips: «En curso», «Hoy».
    labelSmall: TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
  );
}

extension TabularFigures on TextStyle {
  /// Cifras de ancho fijo para porcentajes, MB y duraciones:
  /// el progreso no baila al cambiar los dígitos.
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
