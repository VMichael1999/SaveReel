import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Recuerda el idioma que eligió el usuario. Un archivo con solo el código
/// (`es`, `en`…) basta: es un único dato, como en [OnboardingStore].
class LanguageStore {
  LanguageStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  static const _fileName = 'idioma';

  Future<File> _file() async => File('${(await _directory()).path}/$_fileName');

  /// El código guardado, o nulo si el usuario nunca eligió uno.
  Future<String?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final code = (await file.readAsString()).trim();
      return code.isEmpty ? null : code;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String code) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(code);
  }
}
