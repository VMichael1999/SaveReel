import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Recuerda si el usuario ya vio la guía de primer uso. Basta un archivo
/// marcador: no hace falta una base de datos para un solo dato.
class OnboardingStore {
  OnboardingStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  static const _marker = 'primer_uso_visto';

  Future<File> _file() async => File('${(await _directory()).path}/$_marker');

  Future<bool> isDismissed() async => (await _file()).exists();

  Future<void> dismiss() async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString('1');
  }
}
