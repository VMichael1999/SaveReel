import 'package:flutter/widgets.dart';

import 'translations.g.dart';

/// Los idiomas de la app. El de respaldo es también el que usa el cubit
/// cuando no hay nada guardado, para que ambos coincidan siempre.
abstract final class AppLanguages {
  /// Idioma por omisión y de respaldo si a otro le falta un texto.
  static const String fallback = 'es';

  /// Código → nombre en su propio idioma (no se traduce: cada persona debe
  /// poder reconocer el suyo aunque la app esté en otro).
  static const Map<String, String> names = {'es': 'Español', 'en': 'English'};

  static List<String> get codes => names.keys.toList();

  static List<Locale> get supportedLocales => [
    for (final code in codes) Locale(code),
  ];

  static bool isSupported(String? code) =>
      code != null && names.containsKey(code);

  /// El código de [code] si la app lo tiene; si no, [fallback].
  static String normalize(String? code) => isSupported(code) ? code! : fallback;
}

/// Busca textos por clave en el idioma elegido, con [AppLanguages.fallback]
/// si falta alguno y la propia clave como último recurso.
class AppTexts {
  const AppTexts(this.code);

  /// Código de idioma, por ejemplo `es` o `en`.
  final String code;

  /// El idioma activo para el código que no tiene un [BuildContext] a mano
  /// (notificaciones del sistema, por ejemplo). Lo mantiene el `LocaleCubit`.
  static String active = AppLanguages.fallback;

  /// Los textos del idioma activo, para código sin [BuildContext].
  static AppTexts get current => AppTexts(active);

  /// Los textos del idioma que la app muestra bajo [context]. Si no hay un
  /// [AppLocaleScope] (por ejemplo en una prueba suelta), usa el de respaldo.
  static AppTexts of(BuildContext context) =>
      AppTexts(AppLocaleScope.maybeOf(context)?.code ?? AppLanguages.fallback);

  /// El texto de [key]. Los `{marcadores}` se reemplazan con [args].
  String t(String key, [Map<String, Object?>? args]) {
    final text =
        kTranslations[code]?[key] ??
        kTranslations[AppLanguages.fallback]?[key] ??
        key;
    if (args == null || args.isEmpty) return text;
    return text.replaceAllMapped(
      RegExp(r'\{(\w+)\}'),
      (m) => '${args.containsKey(m[1]) ? args[m[1]] : m[0]}',
    );
  }
}

/// Lleva el idioma elegido a todo el árbol: los widgets que lo consultan se
/// reconstruyen solos cuando cambia.
class AppLocaleScope extends InheritedWidget {
  const AppLocaleScope({super.key, required this.code, required super.child});

  final String code;

  static AppLocaleScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();

  @override
  bool updateShouldNotify(AppLocaleScope old) => old.code != code;
}

/// `'clave'.tr(context)`: el texto de esa clave en el idioma de la app. Si el
/// texto no es una clave conocida, se devuelve tal cual.
extension TranslateKey on String {
  String tr(BuildContext context, [Map<String, Object?>? args]) =>
      AppTexts.of(context).t(this, args);
}
