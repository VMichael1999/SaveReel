import 'package:url_launcher/url_launcher.dart';

/// Abre otras apps del teléfono.
abstract final class AppLauncher {
  /// Abre TikTok. Devuelve `false` si no está instalado o no se pudo abrir.
  static Future<bool> openTikTok() async {
    try {
      return await launchUrl(
        Uri.parse('tiktok://'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
