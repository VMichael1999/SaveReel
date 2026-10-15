// Junta los JSON de `localization/` en un solo archivo de Dart.
//
//   dart run localization/generator.dart
//
// Cada `<idioma>.json` (es.json, en.json…) es un mapa clave → texto. El
// resultado, `lib/src/localization/translations.g.dart`, es un
// `Map<String, Map<String, String>>` que no depende de ningún paquete.
// Para sumar un idioma basta con agregar su JSON y volver a correr esto.
import 'dart:convert';
import 'dart:io';

const String defaultLanguage = 'es';
const String outputPath = 'lib/src/localization/translations.g.dart';

/// Los JSON de [directory] como `{idioma: {clave: texto}}`, ordenados.
Map<String, Map<String, String>> readTranslations(Directory directory) {
  final files =
      directory.listSync().whereType<File>().where((f) {
          return f.path.endsWith('.json');
        }).toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return {
    for (final file in files)
      file.uri.pathSegments.last
          .split('.')
          .first: (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as String)),
  };
}

/// Problemas entre idiomas: claves que faltan o sobran respecto al idioma base
/// y marcadores `{nombre}` que no coinciden. Vacío si todo está en orden.
List<String> checkTranslations(Map<String, Map<String, String>> languages) {
  final base = languages[defaultLanguage];
  if (base == null) return ['Falta $defaultLanguage.json, el idioma base.'];
  final problems = <String>[];
  for (final entry in languages.entries) {
    if (entry.key == defaultLanguage) continue;
    final missing = base.keys.toSet().difference(entry.value.keys.toSet());
    final extra = entry.value.keys.toSet().difference(base.keys.toSet());
    for (final key in missing.toList()..sort()) {
      problems.add('${entry.key}: falta «$key»');
    }
    for (final key in extra.toList()..sort()) {
      problems.add('${entry.key}: sobra «$key» (no está en $defaultLanguage)');
    }
    for (final key in base.keys.where(entry.value.containsKey)) {
      if (!_samePlaceholders(base[key]!, entry.value[key]!)) {
        problems.add('${entry.key}: «$key» no usa los mismos {marcadores}');
      }
    }
  }
  return problems;
}

bool _samePlaceholders(String a, String b) {
  Set<String> of(String text) =>
      RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toSet();
  final left = of(a);
  final right = of(b);
  return left.length == right.length && left.containsAll(right);
}

/// Texto de Dart entre comillas simples, con lo que haga falta escapado.
String dartString(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r');
  return "'$escaped'";
}

/// El contenido de `translations.g.dart`.
String buildSource(Map<String, Map<String, String>> languages) {
  final out =
      StringBuffer()
        ..writeln(
          '// Archivo generado con `dart run localization/generator.dart`.',
        )
        ..writeln('// No lo edites a mano: cambia los JSON de `localization/`.')
        ..writeln('// dart format off')
        ..writeln()
        ..writeln(
          '/// Textos de la app por idioma: `{idioma: {clave: texto}}`.',
        )
        ..writeln('const Map<String, Map<String, String>> kTranslations = {');
  for (final language in languages.entries) {
    out.writeln('  ${dartString(language.key)}: {');
    for (final entry in language.value.entries) {
      out.writeln('    ${dartString(entry.key)}: ${dartString(entry.value)},');
    }
    out.writeln('  },');
  }
  out.writeln('};');
  return out.toString();
}

void main() {
  final languages = readTranslations(Directory('localization'));
  final problems = checkTranslations(languages);
  if (problems.isNotEmpty) {
    stderr.writeln('Hay diferencias entre los idiomas:');
    problems.forEach(stderr.writeln);
    exit(1);
  }
  File(outputPath).writeAsStringSync(buildSource(languages));
  stdout.writeln(
    'Listo: ${languages.length} idiomas '
    '(${languages.keys.join(', ')}) → $outputPath',
  );
}
