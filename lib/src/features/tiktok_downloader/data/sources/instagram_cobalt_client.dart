import 'package:dio/dio.dart';

import '../../../../core/utils/video_link.dart';
import '../../domain/entities/video_data.dart';

/// Pide el video a una instancia de Cobalt (https://github.com/imputnet/cobalt),
/// un descargador de código abierto con API. Sirve de respaldo cuando la
/// página de inserción de Instagram no entrega el video.
class InstagramCobaltClient {
  InstagramCobaltClient({
    required Dio dio,
    required this.baseUrl,
    this.apiKey = '',
  }) : _dio = dio;

  final Dio _dio;
  final String baseUrl;
  final String apiKey;

  bool get isConfigured => baseUrl.isNotEmpty;

  Future<VideoData?> resolve({
    required String link,
    required String shortcode,
  }) async {
    if (!isConfigured) return null;
    final response = await _dio.post<Map<String, dynamic>>(
      baseUrl,
      data: {'url': link, 'videoQuality': 'max'},
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (apiKey.isNotEmpty) 'Authorization': 'Api-Key $apiKey',
        },
      ),
    );
    final url = videoUrlOf(response.data);
    if (url == null) return null;
    return VideoData(
      id: shortcode,
      duration: 0,
      title: '',
      originCover: '',
      playVideo: url,
      wmPlayVideo: url,
      music: '',
      playCount: 0,
      downloadCount: 0,
      network: VideoNetwork.instagram,
    );
  }

  /// Enlace de descarga de la respuesta de Cobalt (`tunnel`, `redirect` o
  /// `picker`), o nulo si dice `error` o no trae video.
  static String? videoUrlOf(Map<String, dynamic>? json) {
    if (json == null) return null;
    switch (json['status']) {
      case 'tunnel' || 'redirect':
        final url = json['url'];
        return url is String && url.isNotEmpty ? url : null;
      case 'picker':
        final items = json['picker'];
        if (items is! List) return null;
        for (final item in items) {
          if (item is Map && item['type'] == 'video') {
            final url = item['url'];
            if (url is String && url.isNotEmpty) return url;
          }
        }
        return null;
      default:
        return null;
    }
  }
}
