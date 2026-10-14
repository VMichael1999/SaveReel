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
