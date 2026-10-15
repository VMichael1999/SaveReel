import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Guarda los ajustes de la app en un archivo JSON.
class SettingsStore {
  SettingsStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  static const _fileName = 'ajustes.json';

  Future<File> _file() async => File('${(await _directory()).path}/$_fileName');

  /// Lo guardado, o un mapa vacío si no hay nada o el archivo está dañado.
  Future<Map<String, dynamic>> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return {};
      final data = jsonDecode(await file.readAsString());
      return data is Map<String, dynamic> ? data : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> write(Map<String, dynamic> values) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(values));
  }
}
