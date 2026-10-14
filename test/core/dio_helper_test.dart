import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/helpers/dio_helper.dart';

void main() {
  test('sin clave no se envían cabeceras de RapidAPI', () {
    final headers = DioHelper.serviceHeaders(apiKey: '');

    expect(headers.keys, ['Content-Type']);
  });

  test('con clave se envían la clave y el host de RapidAPI', () {
    final headers = DioHelper.serviceHeaders(apiKey: 'mi-clave');

    expect(headers['X-RapidAPI-Key'], 'mi-clave');
    expect(headers['X-RapidAPI-Host'], contains('rapidapi.com'));
  });
}
