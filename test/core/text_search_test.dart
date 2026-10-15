import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/utils/text_search.dart';

void main() {
  group('TextSearch.normalize', () {
    test('quita mayúsculas, tildes y espacios de más', () {
      expect(TextSearch.normalize('  CANCIÓN  de   José  '), 'cancion de jose');
      expect(TextSearch.normalize('Ñandú'), 'nandu');
    });
  });

  group('TextSearch.matches', () {
    test('ignora tildes y mayúsculas', () {
      expect(TextSearch.matches('Canción de José', 'cancion'), isTrue);
      expect(TextSearch.matches('cancion de jose', 'JOSÉ'), isTrue);
    });

    test('exige todas las palabras, en cualquier orden', () {
      expect(
        TextSearch.matches('Lomo saltado en 10 minutos', 'minutos lomo'),
        isTrue,
      );
      expect(TextSearch.matches('Lomo saltado', 'lomo arroz'), isFalse);
    });

    test('una búsqueda vacía o de espacios coincide con todo', () {
      expect(TextSearch.matches('lo que sea', ''), isTrue);
      expect(TextSearch.matches('lo que sea', '   '), isTrue);
      expect(TextSearch.matches('', ''), isTrue);
    });

    test('no encuentra lo que no está', () {
      expect(TextSearch.matches('Lomo saltado', 'pizza'), isFalse);
    });
  });
}
