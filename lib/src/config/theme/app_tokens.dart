import 'package:flutter/animation.dart';

/// Espaciado en múltiplos de 4.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Radios de esquina.
abstract final class AppRadii {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

/// Tamaños mínimos de los controles.
abstract final class AppSizes {
  /// Área de toque mínima recomendada.
  static const double touch = 48;
  static const double button = 54;
  static const double input = 54;
  static const double progressBar = 6;
}

/// Duraciones y curvas con nombre. Se sustituyen por [Duration.zero]
/// cuando el sistema pide reducir el movimiento (ver `AppMotion.of`).
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration sheet = Duration(milliseconds: 450);

  /// Un barrido completo del brillo de los marcadores de posición.
  static const Duration shimmer = Duration(milliseconds: 1200);

  /// Para cambios de estado pequeños.
  static const Curve standard = Curves.easeOutCubic;

  /// Para el momento principal: la hoja de vista previa que sube.
  static const Curve emphasized = Curves.easeOutQuart;

  /// Para salidas, que deben ser más rápidas que las entradas.
  static const Curve exit = Curves.easeInCubic;

  /// Devuelve [d] o cero si el usuario desactivó las animaciones.
  static Duration resolve(Duration d, {required bool disableAnimations}) =>
      disableAnimations ? Duration.zero : d;
}
