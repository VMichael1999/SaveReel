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

/// iPhone: la extensión de «Compartir» abre la app con
/// `savetic://share?text=<texto>`.
class SchemeShareSource implements SharedTextSource {
  SchemeShareSource({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  static String? textFrom(Uri? uri) {
    if (uri == null || uri.scheme != 'savetic') return null;
    return uri.queryParameters['text'];
  }

  @override
  Future<String?> initialText() async {
    try {
      return textFrom(await _appLinks.getInitialLink());
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<String> get texts =>
      _appLinks.uriLinkStream
          .map(textFrom)
          .where((text) => text != null)
          .cast<String>();
}

/// Recibe lo que el usuario comparte hacia SaveTic y entrega solo el enlace
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
