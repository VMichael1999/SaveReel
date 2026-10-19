import 'dart:ui';

/// Diseño que corresponde a un tamaño de pantalla, en puntos.
///
/// Se decide solo por el tamaño, nunca por el modelo ni por la orientación
/// del teléfono: un iPhone normal y cualquier teléfono en horizontal caen en
/// [normal], que es lo de siempre.
enum DuoLayout {
  /// Todo lo que no entra en los demás. Sin cambios.
  normal,

  /// Pantalla exterior del iPhone Duo (≈ 466 × 678 pt), también Split View.
  closed,

  /// Pantalla interior abierta en horizontal (≈ 951 × 669 pt).
  openLandscape,

  /// Pantalla interior abierta en vertical (≈ 669 × 951 pt).
  openPortrait,
}

/// Ancho de la franja lateral, en puntos. Es una estimación: Apple no lo
/// publica.
const double kDuoSideBarWidth = 64;

/// Separación a cada lado del centro de la pantalla en [DuoLayout.openLandscape].
const double kDuoFoldGap = 12;

// Rangos por confirmar con Device Hub (los tamaños interiores son inferidos).
const double _closedMinWidth = 420;
const double _closedMaxWidth = 520;
const double _closedMinRatio = 1.3;
const double _closedMaxRatio = 1.6;
const double _openLandscapeMinWidth = 840;
const double _openPortraitMinWidth = 600;

// El Duo abierto es casi cuadrado (≈ 1.42). Un teléfono normal en horizontal
// es mucho más alargado (≈ 2.17) y no debe caer en los diseños abiertos.
const double _openMaxRatio = 1.6;

/// Devuelve el diseño para una pantalla de [size] puntos.
DuoLayout duoLayoutFor(Size size) {
  final width = size.width;
  final height = size.height;
  if (width <= 0 || height <= 0) return DuoLayout.normal;

  if (width >= _openLandscapeMinWidth &&
      width > height &&
      width / height <= _openMaxRatio) {
    return DuoLayout.openLandscape;
  }
  if (width >= _openPortraitMinWidth &&
      height > width &&
      height / width <= _openMaxRatio) {
    return DuoLayout.openPortrait;
  }
  final ratio = height / width;
  if (width >= _closedMinWidth &&
      width <= _closedMaxWidth &&
      ratio >= _closedMinRatio &&
      ratio <= _closedMaxRatio) {
    return DuoLayout.closed;
  }
  return DuoLayout.normal;
}
