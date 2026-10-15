import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/helpers/language_store.dart';
import '../../../../../localization/app_texts.dart';

/// El idioma de la app. Su estado es el [Locale] que usa el `MaterialApp`:
/// al cambiarlo, toda la app se reconstruye con los textos del nuevo idioma.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit({required this.store, Locale Function()? deviceLocale})
    : _deviceLocale =
          deviceLocale ?? (() => PlatformDispatcher.instance.locale),
      super(const Locale(AppLanguages.fallback));

  final LanguageStore store;
  final Locale Function() _deviceLocale;

  /// Carga el idioma guardado. Si el usuario nunca eligió uno, usa el del
  /// teléfono cuando la app lo tiene y, si no, [AppLanguages.fallback].
  Future<void> load() async {
    final saved = await store.read();
    if (isClosed) return;
    _apply(AppLanguages.isSupported(saved) ? saved! : _deviceCode());
  }

  String _deviceCode() => AppLanguages.normalize(_deviceLocale().languageCode);

  /// Cambia el idioma al momento y lo guarda. Un código que la app no tiene se
  /// ignora.
  Future<void> setLanguage(String code) async {
    if (!AppLanguages.isSupported(code) || code == state.languageCode) return;
    _apply(code);
    await store.write(code);
  }

  void _apply(String code) {
    AppTexts.active = code;
    emit(Locale(code));
  }
}
