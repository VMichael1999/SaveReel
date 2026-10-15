import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/features/tiktok_downloader/data/models/instagram_embed_parser.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/media_item.dart';
import 'package:savetic/src/features/tiktok_downloader/data/sources/instagram_cobalt_client.dart';
import 'package:savetic/src/features/tiktok_downloader/data/sources/instagram_video_source.dart';

/// Página de inserción con los datos dentro de un JSON escapado dos veces.
const _escapedPage = r'''
<html><body><script>
window.__additionalDataLoaded('extra',{"shortcode_media":{
\"username\":\"cocinaconlucia\",
\"video_url\":\"https:\\/\\/scontent.cdninstagram.com\\/v\\/clip.mp4?a=1\\u0026b=2\",
\"display_url\":\"https:\\/\\/scontent.cdninstagram.com\\/v\\/cover.jpg?x=1\\u0026y=2\"
}});
</script></body></html>
''';

/// Formato antiguo: la etiqueta `<video>` y las clases del encabezado.
const _tagPage = '''
<div class="Embed"><span class="UsernameText">viajes.peru</span>
<img class="EmbeddedMediaImage" src="https://cdn.ig/cover.jpg?a=1&amp;b=2">
<video class="tvp" src="https://cdn.ig/clip.mp4?a=1&amp;b=2"></video>
<div class="Caption"><a class="CaptionUsername" href="/viajes.peru/">viajes.peru</a><br /><br />Machu Picchu al amanecer &#128525; &amp; más<br /><br />Segunda línea</div></div>
''';

/// Carrusel de una foto, un video y otra foto, con el JSON escapado.
const _carouselPage = r'''
<script>window.__additionalDataLoaded('x',{"shortcode_media":{
\"__typename\":\"GraphSidecar\",\"username\":\"viajes.peru\",
\"display_url\":\"https:\\/\\/cdn.ig\\/portada.jpg\",
\"edge_sidecar_to_children\":{\"edges\":[
{\"node\":{\"__typename\":\"GraphImage\",\"display_url\":\"https:\\/\\/cdn.ig\\/uno.jpg?a=1\\u0026b=2\"}},
{\"node\":{\"__typename\":\"GraphVideo\",\"display_url\":\"https:\\/\\/cdn.ig\\/dos-portada.jpg\",\"video_url\":\"https:\\/\\/cdn.ig\\/dos.mp4\"}},
{\"node\":{\"__typename\":\"GraphImage\",\"display_url\":\"https:\\/\\/cdn.ig\\/tres.jpg\"}}
]}}});</script>
''';

/// Publicación de una sola foto, sin video ni carrusel.
const _photoPage = r'''
<div class="Embed"><span class="UsernameText">viajes.peru</span>
<img class="EmbeddedMediaImage" src="https://cdn.ig/foto.jpg?a=1&amp;b=2"></div>
<script>x={\"display_url\":\"https:\\/\\/cdn.ig\\/foto.jpg?a=1\\u0026b=2\"}</script>
''';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  final List<String> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options.uri.toString());
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _text(String body, [int status = 200]) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: ['text/html'],
  },
);

ResponseBody _json(Map<String, dynamic> body) => ResponseBody.fromString(
  jsonEncode(body),
  200,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

Dio _dio(_FakeAdapter adapter) => Dio()..httpClientAdapter = adapter;

void main() {
  group('InstagramEmbedParser', () {
    test('lee el video, el autor y la portada de un JSON escapado', () {
      final data = InstagramEmbedParser.parse(_escapedPage, shortcode: 'C9x');
      expect(data, isNotNull);
      expect(
        data!.playVideo,
        'https://scontent.cdninstagram.com/v/clip.mp4?a=1&b=2',
      );
      expect(data.authorHandle, 'cocinaconlucia');
      expect(
        data.originCover,
        'https://scontent.cdninstagram.com/v/cover.jpg?x=1&y=2',
      );
      expect(data.id, 'C9x');
      expect(data.music, isEmpty);
    });

    test('lee también la etiqueta video del formato antiguo', () {
      final data = InstagramEmbedParser.parse(_tagPage, shortcode: 'C9y');
      expect(data!.playVideo, 'https://cdn.ig/clip.mp4?a=1&b=2');
      expect(data.authorHandle, 'viajes.peru');
      expect(data.originCover, 'https://cdn.ig/cover.jpg?a=1&b=2');
      expect(data.title, 'Machu Picchu al amanecer 😍 & más');
    });

    test('lee un carrusel con fotos y un video, en orden', () {
      final data = InstagramEmbedParser.parse(_carouselPage, shortcode: 'C9z');

      expect(data, isNotNull);
      expect(data!.isGallery, isTrue);
      expect(data.gallery, [
        const MediaItem(url: 'https://cdn.ig/uno.jpg?a=1&b=2'),
        const MediaItem(url: 'https://cdn.ig/dos.mp4', isVideo: true),
        const MediaItem(url: 'https://cdn.ig/tres.jpg'),
      ]);
      expect(data.photoCount, 2);
      expect(data.authorHandle, 'viajes.peru');
    });

    test('una publicación de una sola foto es una galería de una pieza', () {
      final data = InstagramEmbedParser.parse(_photoPage, shortcode: 'C9p');

      expect(data!.gallery, [
        const MediaItem(url: 'https://cdn.ig/foto.jpg?a=1&b=2'),
      ]);
      expect(data.playVideo, isEmpty);
    });

    test('un video suelto no se toma por una galería', () {
      final data = InstagramEmbedParser.parse(_tagPage, shortcode: 'C9y');
      expect(data!.isGallery, isFalse);
    });

    test('devuelve nulo si la página no trae ningún video', () {
      expect(
        InstagramEmbedParser.parse(
          '<html>Inicia sesión</html>',
          shortcode: 'x',
        ),
        isNull,
      );
    });
  });

  group('InstagramCobaltClient.videoUrlOf', () {
    test('toma el enlace de tunnel, redirect y picker', () {
      expect(
        InstagramCobaltClient.videoUrlOf({'status': 'tunnel', 'url': 'u1'}),
        'u1',
      );
      expect(
        InstagramCobaltClient.videoUrlOf({'status': 'redirect', 'url': 'u2'}),
        'u2',
      );
      expect(
        InstagramCobaltClient.videoUrlOf({
          'status': 'picker',
          'picker': [
            {'type': 'photo', 'url': 'foto'},
            {'type': 'video', 'url': 'u3'},
          ],
        }),
        'u3',
      );
    });

    test('un error o una respuesta rara no da enlace', () {
      expect(InstagramCobaltClient.videoUrlOf({'status': 'error'}), isNull);
      expect(InstagramCobaltClient.videoUrlOf(null), isNull);
    });
  });

  group('InstagramVideoSource', () {
    const link = 'https://www.instagram.com/reel/C9x/';

    test('usa la página de inserción y no molesta a Cobalt', () async {
      final embed = _FakeAdapter((_) => _text(_tagPage));
      final cobaltAdapter = _FakeAdapter((_) => _json({'status': 'error'}));
      final source = InstagramVideoSource(
        dio: _dio(embed),
        cobalt: InstagramCobaltClient(
          dio: _dio(cobaltAdapter),
          baseUrl: 'https://cobalt.ejemplo/',
        ),
      );

      final data = await source.resolve(link: link, shortcode: 'C9x');

      expect(data?.playVideo, 'https://cdn.ig/clip.mp4?a=1&b=2');
      expect(embed.calls.single, contains('/p/C9x/embed/captioned/'));
      expect(cobaltAdapter.calls, isEmpty);
    });

    test('si la inserción no sirve, recurre a Cobalt', () async {
      final embed = _FakeAdapter((_) => _text('<html>login</html>'));
      final cobaltAdapter = _FakeAdapter(
        (_) => _json({'status': 'tunnel', 'url': 'https://tunel/clip'}),
      );
      final source = InstagramVideoSource(
        dio: _dio(embed),
        cobalt: InstagramCobaltClient(
          dio: _dio(cobaltAdapter),
          baseUrl: 'https://cobalt.ejemplo/',
        ),
      );

      final data = await source.resolve(link: link, shortcode: 'C9x');

      expect(data?.playVideo, 'https://tunel/clip');
      expect(cobaltAdapter.calls, hasLength(1));
    });

    test('sin Cobalt configurado y sin video devuelve nulo', () async {
      final source = InstagramVideoSource(
        dio: _dio(_FakeAdapter((_) => _text('<html>login</html>'))),
        cobalt: InstagramCobaltClient(dio: Dio(), baseUrl: ''),
      );
      expect(await source.resolve(link: link, shortcode: 'C9x'), isNull);
    });

    test('una publicación que no existe (404) no se reintenta', () async {
      final source = InstagramVideoSource(
        dio: _dio(_FakeAdapter((_) => _text('no', 404))),
        cobalt: InstagramCobaltClient(dio: Dio(), baseUrl: ''),
      );
      expect(await source.resolve(link: link, shortcode: 'C9x'), isNull);
    });

    test('un fallo de red sin otra fuente se propaga', () async {
      final source = InstagramVideoSource(
        dio: _dio(_FakeAdapter((_) => _text('error', 500))),
        cobalt: InstagramCobaltClient(dio: Dio(), baseUrl: ''),
      );
      expect(
        () => source.resolve(link: link, shortcode: 'C9x'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
