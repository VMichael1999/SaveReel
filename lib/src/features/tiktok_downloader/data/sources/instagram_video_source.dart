import 'package:dio/dio.dart';

import '../../domain/entities/video_data.dart';
import '../models/instagram_embed_parser.dart';
import 'instagram_cobalt_client.dart';

/// Obtiene los datos de un video de Instagram. Prueba primero la página
/// pública de inserción y, si no sirve, una instancia de Cobalt (si hay una
/// configurada). Instagram cambia seguido: cualquiera de las dos puede
/// dejar de funcionar sin aviso.
class InstagramVideoSource {
  InstagramVideoSource({
    required Dio dio,
    required InstagramCobaltClient cobalt,
  }) : _dio = dio,
       _cobalt = cobalt;

  final Dio _dio;
  final InstagramCobaltClient _cobalt;

  static const String _userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
      '(KHTML, like Gecko) Version/17.4 Safari/605.1.15';

  /// Nulo si ninguna fuente entregó el video (privado, borrado o bloqueado).
  /// Un fallo de red no se traga cuando ninguna fuente respondió.
  Future<VideoData?> resolve({
    required String link,
    required String shortcode,
  }) async {
    Object? networkError;

    try {
      final html = await _embedHtml(shortcode);
      final data = InstagramEmbedParser.parse(html, shortcode: shortcode);
      if (data != null) return data;
    } on DioException catch (error) {
      // 404: la publicación no existe o es privada; no hace falta insistir.
      if (error.response?.statusCode != 404) networkError = error;
    }

    try {
      final data = await _cobalt.resolve(link: link, shortcode: shortcode);
      if (data != null) return data;
    } on DioException catch (error) {
      networkError ??= error;
    }

    if (networkError != null) throw networkError;
    return null;
  }

  Future<String> _embedHtml(String shortcode) async {
    final response = await _dio.get<String>(
      'https://www.instagram.com/p/$shortcode/embed/captioned/',
      options: Options(
        headers: {'User-Agent': _userAgent, 'Accept': 'text/html'},
        responseType: ResponseType.plain,
      ),
    );
    return response.data ?? '';
  }
}
