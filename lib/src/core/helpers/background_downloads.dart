import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

import '../utils/app_strings.dart';

/// Lo que se muestra mientras hay descargas en curso: cuántas son, qué título
/// poner y cuánto llevan (nulo si no se sabe).
class BackgroundSnapshot extends Equatable {
  const BackgroundSnapshot({
    required this.count,
    this.title = '',
    this.progress,
  });

  static const BackgroundSnapshot none = BackgroundSnapshot(count: 0);

  final int count;
  final String title;

  /// De 0 a 1, o nulo si no se conoce el avance.
  final double? progress;

  /// Avance en porcentaje entero, o -1 si no se conoce.
  int get percent => progress == null ? -1 : (progress! * 100).floor();

  @override
  List<Object?> get props => [count, title, percent];
}

/// Mantiene viva la descarga cuando la app pasa a segundo plano. Cada sistema
/// lo hace a su manera: un servicio en primer plano con notificación en
/// Android y tiempo extra en iOS.
abstract class BackgroundDownloads {
  /// Informa de las descargas en curso; con [BackgroundSnapshot.none] el
  /// sistema las da por terminadas.
  Future<void> sync(BackgroundSnapshot snapshot);

  /// Avisa que una descarga terminó (o falló) mientras la app no se veía.
  Future<void> notifyFinished({required String title, required bool success});
}

/// No hace nada: para las pruebas y para sistemas sin soporte.
class NoBackgroundDownloads implements BackgroundDownloads {
  const NoBackgroundDownloads();

  @override
  Future<void> sync(BackgroundSnapshot snapshot) async {}

  @override
  Future<void> notifyFinished({
    required String title,
    required bool success,
  }) async {}
}

/// Habla con el código nativo por el canal `savetic/background`. Un error del
/// sistema nunca debe romper una descarga, así que se ignora.
class PlatformBackgroundDownloads implements BackgroundDownloads {
  const PlatformBackgroundDownloads();

  static const MethodChannel _channel = MethodChannel('savetic/background');

  /// Los textos los pone Dart, para que el código nativo no lleve ninguno y
  /// se traduzcan con el resto de la app.
  @override
  Future<void> sync(BackgroundSnapshot snapshot) => _call('sync', {
    'count': snapshot.count,
    'heading':
        snapshot.count > 1
            ? AppStrings.downloadsCount(snapshot.count)
            : AppStrings.downloadingNow,
    'detail': snapshot.count > 1 ? '' : snapshot.title,
    'percent': snapshot.percent,
  });

  @override
  Future<void> notifyFinished({required String title, required bool success}) =>
      _call('finished', {
        'heading': success ? AppStrings.downloadReady : AppStrings.downloadFall,
        'detail': title,
        'success': success,
      });

  Future<void> _call(String method, Map<String, Object?> arguments) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException {
      // Sin permiso de notificaciones o sin servicio: la descarga sigue igual.
    } on MissingPluginException {
      // Sistema sin el canal (pruebas, escritorio).
    }
  }
}
