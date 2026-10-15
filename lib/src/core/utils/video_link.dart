/// Redes de las que SaveReel sabe bajar videos.
enum VideoNetwork { tiktok, instagram }

/// Resultado de revisar el texto que el usuario pegó como enlace.
enum VideoLinkStatus {
  empty,
  valid,

  /// Es un enlace de una red compatible, pero no apunta a un video (por
  /// ejemplo, la portada o un perfil).
  notAVideo,

  /// Es un enlace de otra plataforma conocida; ver [VideoLinkCheck.platform].
  otherPlatform,

  /// No parece un enlace de TikTok ni de Instagram.
  unsupported,
}

class VideoLinkCheck {
  const VideoLinkCheck(this.status, {this.platform, this.network});

  final VideoLinkStatus status;

  /// Nombre de otra plataforma conocida pero no compatible.
  final String? platform;

  /// Red del enlace, cuando es de TikTok o Instagram.
  final VideoNetwork? network;

  bool get isValid => status == VideoLinkStatus.valid;
}

abstract final class VideoLink {
  static const Map<String, String> _otherPlatforms = {
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
      return const VideoLinkCheck(VideoLinkStatus.unsupported);
    }

    if (_isHostOf(host, 'tiktok.com')) {
      final hasPath = uri.pathSegments.any((s) => s.isNotEmpty);
      return VideoLinkCheck(
        hasPath ? VideoLinkStatus.valid : VideoLinkStatus.notAVideo,
        network: VideoNetwork.tiktok,
      );
    }
    if (_isHostOf(host, 'instagram.com') || host == 'instagr.am') {
      return VideoLinkCheck(
        shortcodeOf(text) != null
            ? VideoLinkStatus.valid
            : VideoLinkStatus.notAVideo,
        network: VideoNetwork.instagram,
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
    return const VideoLinkCheck(VideoLinkStatus.unsupported);
  }

  /// El enlace sin parámetros de seguimiento (`?is_from_webapp=1&…`) ni
  /// fragmento, que el servicio no necesita y a veces le estorban. Si no es
  /// un enlace válido, lo devuelve tal cual, sin espacios sobrantes.
  static String normalize(String input) {
    final text = input.trim();
    if (!check(text).isValid) return text;
    final uri = Uri.parse(text.contains('://') ? text : 'https://$text');
    return Uri(scheme: uri.scheme, host: uri.host, path: uri.path).toString();
  }

  /// Red a la que pertenece un enlace válido, o nulo.
  static VideoNetwork? networkOf(String input) {
    final check = VideoLink.check(input);
    return check.isValid ? check.network : null;
  }

  /// Código de una publicación de Instagram (`/reel/<código>/`, `/p/…`,
  /// `/tv/…`), también con el usuario delante (`/usuario/reel/<código>/`).
  /// Nulo si el enlace no apunta a una publicación.
  static String? shortcodeOf(String input) {
    final text = input.trim();
    final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
    if (uri == null) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    for (var i = 0; i < segments.length - 1; i++) {
      if (_instagramKinds.contains(segments[i])) return segments[i + 1];
    }
    return null;
  }

  static const Set<String> _instagramKinds = {'reel', 'reels', 'p', 'tv'};

  /// Busca un enlace válido de TikTok o Instagram dentro de un texto más largo, como el
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
