/// Resultado de revisar el texto que el usuario pegó como enlace.
enum VideoLinkStatus {
  empty,
  valid,

  /// Es un enlace de TikTok, pero no apunta a un video (por ejemplo, la portada).
  notAVideo,

  /// Es un enlace de otra plataforma conocida; ver [VideoLinkCheck.platform].
  otherPlatform,

  /// No parece un enlace de TikTok.
  notTikTok,
}

class VideoLinkCheck {
  const VideoLinkCheck(this.status, {this.platform});

  final VideoLinkStatus status;
  final String? platform;

  bool get isValid => status == VideoLinkStatus.valid;
}

abstract final class VideoLink {
  static const Map<String, String> _otherPlatforms = {
    'instagram.com': 'Instagram',
    'youtube.com': 'YouTube',
    'youtu.be': 'YouTube',
    'facebook.com': 'Facebook',
    'fb.watch': 'Facebook',
    'twitter.com': 'X',
    'x.com': 'X',
  };

  static final RegExp _urlPattern = RegExp(
    r'(?:https?://)?(?:[a-z0-9-]+\.)+[a-z]{2,}(?:/[^\s]*)?',
    caseSensitive: false,
  );

  static VideoLinkCheck check(String input) {
    final text = input.trim();
    if (text.isEmpty) return const VideoLinkCheck(VideoLinkStatus.empty);

    final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
    final host = uri?.host.toLowerCase() ?? '';
    if (uri == null || !host.contains('.') || text.contains(' ')) {
      return const VideoLinkCheck(VideoLinkStatus.notTikTok);
    }

    if (_isHostOf(host, 'tiktok.com')) {
      final hasPath = uri.pathSegments.any((s) => s.isNotEmpty);
      return VideoLinkCheck(
        hasPath ? VideoLinkStatus.valid : VideoLinkStatus.notAVideo,
      );
    }
    for (final entry in _otherPlatforms.entries) {
      if (_isHostOf(host, entry.key)) {
        return VideoLinkCheck(
          VideoLinkStatus.otherPlatform,
          platform: entry.value,
        );
      }
    }
    return const VideoLinkCheck(VideoLinkStatus.notTikTok);
  }

  /// Busca un enlace de TikTok válido dentro de un texto más largo, como el
  /// que queda en el portapapeles al copiar desde la app. Devuelve nulo si no hay.
  static String? find(String text) {
    for (final match in _urlPattern.allMatches(text)) {
      final candidate = match.group(0)!;
      if (check(candidate).isValid) return candidate;
    }
    return null;
  }

  static bool _isHostOf(String host, String domain) =>
      host == domain || host.endsWith('.$domain');
}
