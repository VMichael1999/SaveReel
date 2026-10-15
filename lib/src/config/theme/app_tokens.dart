import 'package:flutter/animation.dart';

/// Espaciado en múltiplos de 4.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Para el aire sobre un bloque grande, como bajo la sombra del reproductor.
  static const double xxxl = 64;
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

  /// Íconos: pequeño (junto a texto), mediano y de insignia sobre miniaturas.
  static const double iconSm = 16;
  static const double iconMd = 18;
  static const double iconBadge = 13;

  /// Indicador de carga dentro de un botón y el grosor de su trazo.
  static const double loader = 24;
  static const double loaderStroke = 2.5;

  /// Marca de SaveTic: en la barra, en el splash y en el catálogo.
  static const double markBar = 26;
  static const double markSplash = 88;
  static const double markLarge = 48;

  /// Círculo numerado de la guía de primer uso.
  static const double stepBadge = 34;

  /// Botón central y fondo de audio del reproductor.
  static const double playButton = 68;
  static const double playIcon = 36;
  static const double backdropIcon = 96;

  /// Grosor de los bordes finos.
  static const double borderThin = 1.5;

  /// Aviso: círculo del ícono de estado y ancho máximo en pantallas grandes.
  static const double toastBadge = 36;
  static const double toastMaxWidth = 520;
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
}

/// Colores de los controles dibujados sobre el video. Son iguales en el
/// tema claro y en el oscuro, porque el video siempre es el fondo.
abstract final class AppOverlay {
  static const Color onVideo = Color(0xFFFFFFFF);
  static const Color onVideoMuted = Color(0xCCFFFFFF);
  static const Color controlFill = Color(0x66000000);
  static const Color actionFill = Color(0x1FFFFFFF);
  static const Color track = Color(0x47FFFFFF);
  static const Color shadeTop = Color(0x73000000);
  static const Color shadeBottom = Color(0xD1000000);
  static const Color clear = Color(0x00000000);

  /// Verde menta para el «listo» sobre el video, en ambos temas.
  static const Color done = Color(0xFF4DF0D8);
  static const Color videoBackground = Color(0xFF000000);
}
