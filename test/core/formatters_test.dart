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

  group('formatMegabytes', () {
    test('muestra MB con un decimal', () {
      expect(formatMegabytes(9542041), '9.1 MB');
      expect(formatMegabytes(524288), '0.5 MB');
    });

    test('puede omitir la unidad para mostrar «4.7 de 7.6 MB»', () {
      expect(formatMegabytes(4928307, withUnit: false), '4.7');
    });

    test('nunca muestra 0.0 MB', () {
      expect(formatMegabytes(1000), '0.1 MB');
    });
  });

  group('formatRemaining', () {
    test('estima los segundos que faltan según el ritmo', () {
      // 25 % en 1 s: faltan 3 s.
      expect(
        formatRemaining(
          elapsed: const Duration(seconds: 1),
          receivedBytes: 25,
          totalBytes: 100,
        ),
        'faltan 3 s',
      );
    });

    test('pasa a minutos cuando falta más de un minuto', () {
      expect(
        formatRemaining(
          elapsed: const Duration(seconds: 10),
          receivedBytes: 10,
          totalBytes: 100,
        ),
        'faltan 1 min 30 s',
      );
    });

    test('no estima sin datos suficientes', () {
      expect(
        formatRemaining(
          elapsed: const Duration(milliseconds: 100),
          receivedBytes: 10,
          totalBytes: 100,
        ),
        isNull,
      );
      expect(
        formatRemaining(
          elapsed: const Duration(seconds: 2),
          receivedBytes: 0,
          totalBytes: 100,
        ),
        isNull,
      );
    });
  });
}
