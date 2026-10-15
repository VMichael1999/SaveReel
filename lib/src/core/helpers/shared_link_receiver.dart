import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/video_link.dart';

/// De dónde llega un texto compartido desde otra app.
abstract class SharedTextSource {
  /// El texto con el que se abrió la app, si se abrió desde «Compartir».
  Future<String?> initialText();

  /// Los textos que llegan con la app ya abierta.
  Stream<String> get texts;
}

/// Android: la app aparece en la hoja de «Compartir» y recibe el texto por un
/// canal propio (ver `MainActivity.kt`).
class AndroidShareSource implements SharedTextSource {
  AndroidShareSource({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('savetic/share') {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedText' && call.arguments is String) {
        _controller.add(call.arguments as String);
      }
      return null;
    });
  }

  final MethodChannel _channel;
  final StreamController<String> _controller = StreamController.broadcast();

  @override
  Future<String?> initialText() async {
    try {
      return await _channel.invokeMethod<String>('getInitialText');
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Stream<String> get texts => _controller.stream;
}

/// Fuentes que además avisan cuando se pidió «guardar el enlace copiado» y no
/// había ninguno.
abstract class MissingLinkSource {
  Stream<void> get missing;
}

/// Lee el texto del portapapeles, o nulo si no hay.
typedef ClipboardReader = Future<String?> Function();

/// Enlaces `savetic://…`: los abren la extensión de «Compartir» de iPhone
/// (`savetic://share?text=<texto>`) y los atajos del sistema en las dos
/// plataformas (`savetic://clipboard`, que pide usar el enlace copiado).
class SchemeShareSource implements SharedTextSource, MissingLinkSource {
  SchemeShareSource({
    AppLinks? appLinks,
    Future<Uri?> Function()? initialUri,
    Stream<Uri>? uris,
    ClipboardReader? readClipboard,
  }) : _initialUri = initialUri ?? _initialOf(appLinks ?? AppLinks()),
       _uris = uris ?? (appLinks ?? AppLinks()).uriLinkStream,
       _readClipboard = readClipboard ?? readClipboardWithRetry;

  final Future<Uri?> Function() _initialUri;
  final Stream<Uri> _uris;
  final ClipboardReader _readClipboard;
  final StreamController<void> _missing = StreamController.broadcast();

  static Future<Uri?> Function() _initialOf(AppLinks links) =>
      () => links.getInitialLink();

  static String? textFrom(Uri? uri) {
    if (uri == null || uri.scheme != 'savetic') return null;
    return uri.queryParameters['text'];
  }

  /// Si el enlace es el atajo «guardar el enlace copiado».
  static bool isClipboardShortcut(Uri? uri) =>
      uri != null && uri.scheme == 'savetic' && uri.host == 'clipboard';

  /// El portapapeles puede tardar en dejarse leer: Android lo niega hasta que
  /// la app tiene el foco, que llega unos instantes después de abrirse.
  static Future<String?> readClipboardWithRetry({
    int attempts = 5,
    Duration delay = const Duration(milliseconds: 250),
  }) async {
    for (var i = 0; i < attempts; i++) {
      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final text = data?.text;
        if (text != null && text.trim().isNotEmpty) return text;
      } on PlatformException {
        // Sin acceso todavía: se vuelve a intentar.
      }
      if (i < attempts - 1) await Future<void>.delayed(delay);
    }
    return null;
  }

  Future<String?> _resolve(Uri? uri) async {
    if (!isClipboardShortcut(uri)) return textFrom(uri);
    final text = await _readClipboard();
    if (SharedLinkReceiver.linkIn(text) == null) {
      _missing.add(null);
      return null;
    }
    return text;
  }

  @override
  Future<String?> initialText() async {
    try {
      return await _resolve(await _initialUri());
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<String> get texts =>
      _uris.asyncMap(_resolve).where((text) => text != null).cast<String>();

  @override
  Stream<void> get missing => _missing.stream;
}

/// Recibe lo que el usuario comparte hacia SaveReel y entrega solo el enlace
/// de TikTok que haya dentro del texto.
class SharedLinkReceiver {
  SharedLinkReceiver({List<SharedTextSource>? sources})
    : _sources = sources ?? _platformSources();

  final List<SharedTextSource> _sources;

  static List<SharedTextSource> _platformSources() => [
    if (defaultTargetPlatform == TargetPlatform.android) AndroidShareSource(),
    SchemeShareSource(),
  ];

  /// Enlace de TikTok dentro de [text], o nulo si no hay.
  static String? linkIn(String? text) =>
      text == null ? null : VideoLink.find(text);

  /// El enlace con el que se abrió la app, si vino de «Compartir».
  Future<String?> initialLink() async {
    for (final source in _sources) {
      final link = linkIn(await source.initialText());
      if (link != null) return link;
    }
    return null;
  }

  /// Las veces que se pidió usar el enlace copiado y no había ninguno.
  Stream<void> get missingLinks {
    final controller = StreamController<void>.broadcast();
    for (final source in _sources) {
      if (source is MissingLinkSource) {
        (source as MissingLinkSource).missing.listen(controller.add);
      }
    }
    return controller.stream;
  }

  /// Los enlaces que llegan con la app abierta.
  Stream<String> get links {
    final controller = StreamController<String>.broadcast();
    for (final source in _sources) {
      source.texts.listen((text) {
        final link = linkIn(text);
        if (link != null) controller.add(link);
      });
    }
    return controller.stream;
  }
}
