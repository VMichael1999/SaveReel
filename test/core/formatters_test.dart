import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/utils/formatters.dart';

void main() {
  group('formatDuration', () {
    test('muestra minutos y segundos con dos dígitos', () {
      expect(formatDuration(34), '0:34');
      expect(formatDuration(72), '1:12');
      expect(formatDuration(5), '0:05');
      expect(formatDuration(600), '10:00');
    });

    test('no muestra tiempos negativos', () {
      expect(formatDuration(-3), '0:00');
    });
  });

  group('formatCount', () {
    test('deja intactos los números chicos', () {
      expect(formatCount(0), '0');
      expect(formatCount(950), '950');
    });

    test('abrevia miles y millones con un decimal', () {
      expect(formatCount(18600), '18.6 K');
      expect(formatCount(1200000), '1.2 M');
    });

    test('quita el decimal cuando es cero', () {
      expect(formatCount(2000), '2 K');
      expect(formatCount(3000000), '3 M');
    });
  });
}
