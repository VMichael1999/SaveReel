import 'package:flutter/services.dart';

/// Qué tipo de red hay en este momento. Solo distingue si es de pago (datos
/// móviles, punto de acceso del teléfono o modo de datos reducidos), que es lo
/// que importa para no gastar los datos de nadie sin avisar.
class NetworkInfo {
  static const MethodChannel _channel = MethodChannel('savetic/network');

  /// Si la conexión actual es de pago. Ante la duda (sin canal, error) dice
  /// que no, para no bloquear una descarga por no poder saberlo. Es una
  /// variable para poder cambiarla en las pruebas.
  static Future<bool> Function() isMetered = _platformIsMetered;

  static Future<bool> _platformIsMetered() async {
    try {
      return await _channel.invokeMethod<bool>('isMetered') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
