import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/helpers/shared_link_receiver.dart';

class _FakeSource implements SharedTextSource {
  _FakeSource({this.initial});

  final String? initial;
  final StreamController<String> controller = StreamController.broadcast();

  @override
  Future<String?> initialText() async => initial;

  @override
  Stream<String> get texts => controller.stream;
}

void main() {
  group('SharedLinkReceiver.linkIn', () {
    test('saca el enlace de TikTok del texto que comparte la app', () {
      expect(
        SharedLinkReceiver.linkIn(
          'Mira este video https://vm.tiktok.com/ZMh7K2pQx/ 🔥',
        ),
        'https://vm.tiktok.com/ZMh7K2pQx/',
      );
    });

    test('devuelve nulo si no hay un enlace compatible', () {
      expect(SharedLinkReceiver.linkIn('https://youtu.be/abc123'), isNull);
      expect(SharedLinkReceiver.linkIn('solo texto'), isNull);
      expect(SharedLinkReceiver.linkIn(null), isNull);
    });
  });

  group('SchemeShareSource.textFrom', () {
    test('lee el texto de savetic://share?text=…', () {
      final uri = Uri.parse(
        'savetic://share?text=${Uri.encodeComponent('https://vm.tiktok.com/ZMh7K2pQx/')}',
      );

      expect(
        SchemeShareSource.textFrom(uri),
        'https://vm.tiktok.com/ZMh7K2pQx/',
      );
    });

    test('ignora otros esquemas y enlaces vacíos', () {
      expect(
        SchemeShareSource.textFrom(Uri.parse('https://a.com?text=x')),
        isNull,
      );
      expect(SchemeShareSource.textFrom(null), isNull);
      expect(SchemeShareSource.textFrom(Uri.parse('savetic://share')), isNull);
    });
  });

  group('SharedLinkReceiver', () {
    test('entrega el enlace con el que se abrió la app', () async {
      final receiver = SharedLinkReceiver(
        sources: [
          _FakeSource(),
          _FakeSource(initial: 'mira https://vm.tiktok.com/ZMabc123/'),
        ],
      );

      expect(await receiver.initialLink(), 'https://vm.tiktok.com/ZMabc123/');
    });

    test('sin nada compartido no hay enlace inicial', () async {
      final receiver = SharedLinkReceiver(sources: [_FakeSource()]);

      expect(await receiver.initialLink(), isNull);
    });

    test(
      'entrega los enlaces que llegan después y descarta el resto',
      () async {
        final source = _FakeSource();
        final receiver = SharedLinkReceiver(sources: [source]);
        final received = <String>[];
        final sub = receiver.links.listen(received.add);

        source.controller.add('hola');
        source.controller.add('https://vm.tiktok.com/ZMabc123/');
        await Future<void>.delayed(Duration.zero);

        expect(received, ['https://vm.tiktok.com/ZMabc123/']);
        await sub.cancel();
      },
    );
  });
}
