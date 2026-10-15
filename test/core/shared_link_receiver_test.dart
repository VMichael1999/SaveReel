import 'dart:async';

import 'package:flutter/services.dart';
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

  group('atajo «guardar el enlace copiado»', () {
    const link = 'https://www.tiktok.com/@autor/video/7412345678901234567';

    SchemeShareSource source({
      Uri? initial,
      Stream<Uri>? uris,
      String? clipboard,
    }) => SchemeShareSource(
      initialUri: () async => initial,
      uris: uris ?? const Stream<Uri>.empty(),
      readClipboard: () async => clipboard,
    );

    test('reconoce savetic://clipboard y nada más', () {
      expect(
        SchemeShareSource.isClipboardShortcut(Uri.parse('savetic://clipboard')),
        isTrue,
      );
      expect(
        SchemeShareSource.isClipboardShortcut(Uri.parse('savetic://share')),
        isFalse,
      );
      expect(
        SchemeShareSource.isClipboardShortcut(
          Uri.parse('https://clipboard.com'),
        ),
        isFalse,
      );
      expect(SchemeShareSource.isClipboardShortcut(null), isFalse);
    });

    test(
      'abierta con el atajo, usa el enlace que haya en el portapapeles',
      () async {
        final s = source(
          initial: Uri.parse('savetic://clipboard'),
          clipboard: 'mira esto $link 🔥',
        );

        expect(await s.initialText(), 'mira esto $link 🔥');
      },
    );

    test('con el atajo y sin enlace copiado avisa que falta', () async {
      final s = source(
        initial: Uri.parse('savetic://clipboard'),
        clipboard: 'solo texto',
      );
      var missing = 0;
      final sub = s.missing.listen((_) => missing++);

      expect(await s.initialText(), isNull);
      await Future<void>.delayed(Duration.zero);

      expect(missing, 1);
      await sub.cancel();
    });

    test('con el portapapeles vacío también avisa', () async {
      final s = source(initial: Uri.parse('savetic://clipboard'));
      var missing = 0;
      final sub = s.missing.listen((_) => missing++);

      await s.initialText();
      await Future<void>.delayed(Duration.zero);

      expect(missing, 1);
      await sub.cancel();
    });

    test('con la app abierta, el atajo entrega el enlace copiado', () async {
      final uris = StreamController<Uri>();
      final s = source(uris: uris.stream, clipboard: link);
      final texts = <String>[];
      final sub = s.texts.listen(texts.add);

      uris.add(Uri.parse('savetic://clipboard'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(texts, [link]);
      await sub.cancel();
      await uris.close();
    });

    test('compartir sigue funcionando por el mismo esquema', () async {
      final shared = Uri.parse(
        'savetic://share?text=${Uri.encodeComponent(link)}',
      );
      final s = source(initial: shared, clipboard: 'otro texto');

      expect(await s.initialText(), link);
    });

    test('el receptor reenvía los avisos de enlace faltante', () async {
      final s = source(
        initial: Uri.parse('savetic://clipboard'),
        clipboard: '',
      );
      final receiver = SharedLinkReceiver(sources: [s]);
      var missing = 0;
      final sub = receiver.missingLinks.listen((_) => missing++);

      expect(await receiver.initialLink(), isNull);
      await Future<void>.delayed(Duration.zero);

      expect(missing, 1);
      await sub.cancel();
    });
  });

  group('SchemeShareSource.readClipboardWithRetry', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    void answerWith(List<String?> texts) {
      var call = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (c) async {
            if (c.method != 'Clipboard.getData') return null;
            final text = texts[call.clamp(0, texts.length - 1)];
            call++;
            return text == null ? null : {'text': text};
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
    }

    test('reintenta hasta que el portapapeles se deja leer', () async {
      answerWith([null, '', 'ya hay texto']);

      final text = await SchemeShareSource.readClipboardWithRetry(
        delay: Duration.zero,
      );

      expect(text, 'ya hay texto');
    });

    test('si nunca hay texto, se rinde con nulo', () async {
      answerWith([null]);

      final text = await SchemeShareSource.readClipboardWithRetry(
        attempts: 3,
        delay: Duration.zero,
      );

      expect(text, isNull);
    });
  });
}
