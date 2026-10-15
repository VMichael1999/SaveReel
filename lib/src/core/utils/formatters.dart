import 'app_strings.dart';

/// Duración en segundos como `0:34` o `1:12`.
String formatDuration(int seconds) {
  final total = seconds < 0 ? 0 : seconds;
  final minutes = total ~/ 60;
  final rest = (total % 60).toString().padLeft(2, '0');
  return '$minutes:$rest';
}

/// Cantidades en forma corta: `950`, `18.6 K`, `1.2 M`.
String formatCount(int value) {
  if (value >= 1000000) return '${_oneDecimal(value / 1000000)} M';
  if (value >= 1000) return '${_oneDecimal(value / 1000)} K';
  return '$value';
}

String _oneDecimal(double v) {
  final text = v.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

/// Peso de un archivo, siempre en MB con un decimal: `9.1 MB`.
String formatMegabytes(int bytes, {bool withUnit = true}) {
  if (bytes <= 0) return withUnit ? '0 MB' : '0';
  final mb = bytes / (1024 * 1024);
  final number = (mb < 0.1 ? 0.1 : mb).toStringAsFixed(1);
  return withUnit ? '$number MB' : number;
}

/// Tiempo restante estimado: `faltan 3 s`, `faltan 1 min 20 s` (o `3 s left`).
/// Devuelve nulo mientras no hay datos suficientes para estimarlo.
String? formatRemaining({
  required AppStrings strings,
  required Duration elapsed,
  required int receivedBytes,
  required int totalBytes,
}) {
  if (receivedBytes <= 0 || totalBytes <= receivedBytes) return null;
  if (elapsed.inMilliseconds < 500) return null;
  final remainingMs =
      elapsed.inMilliseconds * (totalBytes - receivedBytes) / receivedBytes;
  final seconds = (remainingMs / 1000).ceil();
  return strings.remaining(seconds);
}
