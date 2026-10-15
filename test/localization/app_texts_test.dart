import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/utils/app_strings.dart';
import 'package:savetic/src/localization/app_texts.dart';
import 'package:savetic/src/localization/translations.g.dart';

import '../../localization/generator.dart' as generator;

void main() {
  tearDown(() => AppTexts.active = AppLanguages.fallback);

  group('AppTexts', () {
    test('busca la clave en el idioma pedido', () {
      expect(const AppTexts('en').t('settingsLanguage'), 'Language');
      expect(const AppTexts('es').t('settingsLanguage'), 'Idioma');
    });

    test('un idioma que no existe cae al de respaldo', () {
      expect(const AppTexts('fr').t('settingsLanguage'), 'Idioma');
    });

    test('una clave que no existe devuelve la clave', () {
      expect(const AppTexts('en').t('noExiste'), 'noExiste');
    });

    test('reemplaza los datos entre llaves', () {
      expect(const AppTexts('en').t('downloadsCount', {'n': 3}), contains('3'));
    });

    test('el idioma de respaldo es el mismo que el inicial del cubit', () {
      expect(AppLanguages.fallback, 'es');
      expect(AppLanguages.supportedLocales.first.languageCode, 'es');
    });

    test('normalize deja el de respaldo cuando el código no se tiene', () {
      expect(AppLanguages.normalize('en'), 'en');
      expect(AppLanguages.normalize('ja'), AppLanguages.fallback);
    });
  });

  group('traducciones', () {
    test('todos los idiomas tienen las mismas claves y datos', () {
      final languages = generator.readTranslations(Directory('localization'));
      expect(generator.checkTranslations(languages), isEmpty);
    });

    test('translations.g.dart está al día con los JSON', () {
      final languages = generator.readTranslations(Directory('localization'));
      final current =
          File('lib/src/localization/translations.g.dart').readAsStringSync();
      expect(current, generator.buildSource(languages));
    });

    test('el mapa generado trae cada idioma soportado', () {
      expect(kTranslations.keys.toSet(), AppLanguages.codes.toSet());
    });
  });

  group('AppStrings', () {
    test('los plurales cambian con la cantidad', () {
      AppTexts.active = 'en';
      final s = AppStrings.current;
      expect(s.selectedCount(1), isNot(s.selectedCount(2)));
      expect(s.selectedCount(2), contains('2'));
    });

    test('translate traduce una clave y deja pasar un texto suelto', () {
      AppTexts.active = 'en';
      expect(AppStrings.current.translate('errCancel'), isNot('errCancel'));
      expect(AppStrings.current.translate('Hola'), 'Hola');
    });

    testWidgets('context.strings sigue al idioma del scope', (tester) async {
      String? seen;
      Future<void> pump(String code) => tester.pumpWidget(
        AppLocaleScope(
          code: code,
          child: Builder(
            builder: (context) {
              seen = context.strings.settingsLanguage;
              return const SizedBox();
            },
          ),
        ),
      );
      await pump('es');
      expect(seen, 'Idioma');
      await pump('en');
      expect(seen, 'Language');
    });
  });
}
