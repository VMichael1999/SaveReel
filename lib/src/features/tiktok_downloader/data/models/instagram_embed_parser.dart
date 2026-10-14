import '../../../../core/utils/video_link.dart';
import '../../domain/entities/video_data.dart';

/// Lee la página pública de inserción de Instagram (`/p/<código>/embed/`) y
/// saca de ella los datos del video. Es texto sin formato estable: si
/// Instagram cambia la página, devuelve nulo en vez de fallar.
abstract final class InstagramEmbedParser {
  static VideoData? parse(String html, {required String shortcode}) {
    final video = _jsonString(html, 'video_url') ?? _videoTag(html);
    if (video == null || video.isEmpty) return null;

    final handle =
        _jsonString(html, 'username') ?? _firstGroup(html, _usernameText);
    final cover =
        _jsonString(html, 'display_url') ??
        _jsonString(html, 'thumbnail_src') ??
        _firstGroup(html, _embeddedImage) ??
        '';
    final caption = _caption(html);

    return VideoData(
      id: shortcode,
      duration: 0,
      title: caption ?? (handle == null ? '' : 'Video de @$handle'),
      originCover: cover,
      playVideo: video,
      wmPlayVideo: video,
      music: '',
      playCount: 0,
      downloadCount: 0,
      network: VideoNetwork.instagram,
      authorHandle: handle,
    );
  }

  static final RegExp _usernameText = RegExp(
    r'class="UsernameText"[^>]*>([^<]+)<',
  );
  static final RegExp _embeddedImage = RegExp(
    r'class="EmbeddedMediaImage"[^>]*src="([^"]+)"',
  );
  static final RegExp _videoSrc = RegExp(r'<video[^>]*\ssrc="([^"]+)"');

  /// Valor de `"clave":"…"` aunque la página lo traiga escapado una o dos
  /// veces dentro de otro texto JSON.
  static String? _jsonString(String html, String key) {
    final match = RegExp(
      '\\\\*"$key\\\\*"\\s*:\\s*\\\\*"((?:[^"\\\\]|\\\\.)*?)\\\\*"(?=[,}\\s])',
    ).firstMatch(html);
    final raw = match?.group(1);
    return raw == null ? null : _unescape(raw);
  }

  static String? _videoTag(String html) {
    final raw = _videoSrc.firstMatch(html)?.group(1);
    return raw == null ? null : _unescape(raw);
  }

  static String? _caption(String html) {
    final match = RegExp(
      r'"edge_media_to_caption".*?"text"\s*:\s*"((?:[^"\\]|\\.)*)"',
      dotAll: true,
    ).firstMatch(html);
    final text = match == null ? null : _unescape(match.group(1)!).trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String? _firstGroup(String html, RegExp pattern) {
    final raw = pattern.firstMatch(html)?.group(1);
    return raw == null ? null : _unescape(raw);
  }

  static String _unescape(String value) {
    var text = value;
    for (var i = 0; i < 3; i++) {
      final next = text
          .replaceAll(r'\\', r'\')
          .replaceAll(r'\/', '/')
          .replaceAll(r'\"', '"')
          .replaceAll('&amp;', '&');
      if (next == text) break;
      text = next;
    }
    return text
        .replaceAllMapped(
          RegExp(r'\\u([0-9a-fA-F]{4})'),
          (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
        )
        .replaceAll(r'\n', '\n');
  }
}
