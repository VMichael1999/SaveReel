import '../../../../core/utils/video_link.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/video_data.dart';

/// Lee la página pública de inserción de Instagram (`/p/<código>/embed/`) y
/// saca de ella los datos del video. Es texto sin formato estable: si
/// Instagram cambia la página, devuelve nulo en vez de fallar.
abstract final class InstagramEmbedParser {
  static VideoData? parse(String html, {required String shortcode}) {
    final gallery = _gallery(html);
    final video = _jsonString(html, 'video_url') ?? _videoTag(html);
    final hasVideo = video != null && video.isNotEmpty;
    if (!hasVideo && gallery.isEmpty) return null;

    final handle =
        _jsonString(html, 'username') ?? _firstGroup(html, _usernameText);
    final cover =
        _jsonString(html, 'display_url') ??
        _jsonString(html, 'thumbnail_src') ??
        _firstGroup(html, _embeddedImage) ??
        '';
    final caption = _caption(html) ?? _captionBlock(html);

    return VideoData(
      id: shortcode,
      duration: 0,
      title: caption ?? (handle == null ? '' : 'Video de @$handle'),
      originCover: cover,
      playVideo: hasVideo ? video : '',
      wmPlayVideo: hasVideo ? video : '',
      music: '',
      playCount: 0,
      downloadCount: 0,
      network: VideoNetwork.instagram,
      gallery: gallery,
      authorHandle: handle,
    );
  }

  /// Piezas de un carrusel (`edge_sidecar_to_children`) o, si no hay video
  /// ni carrusel, la foto de una publicación de una sola imagen. Vacío si el
  /// video suelto basta.
  static List<MediaItem> _gallery(String html) {
    final start = RegExp(r'edge_sidecar_to_children').firstMatch(html)?.end;
    if (start != null) {
      final items = <MediaItem>[];
      for (final chunk in html.substring(start).split('__typename')) {
        final video = _jsonString(chunk, 'video_url');
        final photo = _jsonString(chunk, 'display_url');
        if (video != null && video.isNotEmpty) {
          items.add(MediaItem(url: video, isVideo: true));
        } else if (photo != null && photo.isNotEmpty) {
          items.add(MediaItem(url: photo));
        }
      }
      if (items.isNotEmpty) return items;
    }
    final hasVideo =
        _jsonString(html, 'video_url') != null || _videoTag(html) != null;
    final photo = _jsonString(html, 'display_url');
    if (!hasVideo && photo != null && photo.isNotEmpty) {
      return [MediaItem(url: photo)];
    }
    return const [];
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

  /// Pie del video en el formato HTML de la página: `<div class="Caption">`
  /// con el autor en un enlace, saltos `<br />` y entidades.
  static String? _captionBlock(String html) {
    final match = RegExp(
      r'<div class="Caption">(.*?)</div>',
      dotAll: true,
    ).firstMatch(html);
    if (match == null) return null;
    var text = match
        .group(1)!
        .replaceAll(
          RegExp(r'<a class="CaptionUsername".*?</a>', dotAll: true),
          '',
        )
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '');
    text = text
        .replaceAllMapped(
          RegExp(r'&#(x?)([0-9a-fA-F]+);'),
          (m) => String.fromCharCode(
            int.parse(m.group(2)!, radix: m.group(1) == 'x' ? 16 : 10),
          ),
        )
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty);
    if (lines.isEmpty) return null;
    final first = lines.first;
    return first.length <= 120 ? first : '${first.substring(0, 117)}…';
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
