import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/helpers/shared_link_receiver.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/shared_link_cubit/shared_link_cubit.dart';

class _Source implements SharedTextSource {
  _Source({this.initial});

  final String? initial;
  final StreamController<String> controller = StreamController.broadcast();

  @override
  Future<String?> initialText() async => initial;

  @override
  Stream<String> get texts => controller.stream;
}

void main() {
  test(
    'con la app abierta desde «Compartir» deja el enlace pendiente',
    () async {
      final cubit = SharedLinkCubit(
        receiver: SharedLinkReceiver(
          sources: [_Source(initial: 'https://vm.tiktok.com/ZMabc123/')],
        ),
      );

      await cubit.start();

      expect(cubit.state.pending, 'https://vm.tiktok.com/ZMabc123/');
      await cubit.close();
    },
  );

  test('un enlace que llega después también queda pendiente', () async {
    final source = _Source();
    final cubit = SharedLinkCubit(
      receiver: SharedLinkReceiver(sources: [source]),
    );
    await cubit.start();

    source.controller.add('ve esto https://vm.tiktok.com/ZMxyz789/');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.pending, 'https://vm.tiktok.com/ZMxyz789/');
    await cubit.close();
  });

  test(
    'usar el enlace lo limpia, y el mismo enlace dos veces se nota',
    () async {
      final source = _Source();
      final cubit = SharedLinkCubit(
        receiver: SharedLinkReceiver(sources: [source]),
      );
      await cubit.start();

      source.controller.add('https://vm.tiktok.com/ZMabc123/');
      await Future<void>.delayed(Duration.zero);
      final first = cubit.state;
      expect(cubit.consume(), 'https://vm.tiktok.com/ZMabc123/');
      expect(cubit.state.pending, isNull);

      source.controller.add('https://vm.tiktok.com/ZMabc123/');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.pending, 'https://vm.tiktok.com/ZMabc123/');
      expect(cubit.state.serial, greaterThan(first.serial));
      await cubit.close();
    },
  );

  test('lo que no trae un enlace de TikTok se ignora', () async {
    final source = _Source();
    final cubit = SharedLinkCubit(
      receiver: SharedLinkReceiver(sources: [source]),
    );
    await cubit.start();

    source.controller.add('solo texto');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.pending, isNull);
    await cubit.close();
  });

  test(
    'pedir usar el enlace copiado sin que haya lo deja pendiente de avisar',
    () async {
      final source = _MissingSource();
      final cubit = SharedLinkCubit(
        receiver: SharedLinkReceiver(sources: [source]),
      );
      await cubit.start();
      expect(cubit.state.missing, isFalse);

      source.missingController.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.missing, isTrue);
      expect(cubit.state.pending, isNull);
      await cubit.close();
    },
  );

  test('consumeMissing avisa una sola vez', () async {
    final source = _MissingSource();
    final cubit = SharedLinkCubit(
      receiver: SharedLinkReceiver(sources: [source]),
    );
    await cubit.start();
    source.missingController.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.consumeMissing(), isTrue);
    expect(cubit.consumeMissing(), isFalse);
    expect(cubit.state.missing, isFalse);
    await cubit.close();
  });

  test('avisar o usar el enlace pendiente no se pisan entre sí', () async {
    final source = _MissingSource();
    final cubit = SharedLinkCubit(
      receiver: SharedLinkReceiver(sources: [source]),
    );
    await cubit.start();
    source.missingController.add(null);
    await Future<void>.delayed(Duration.zero);
    source.controller.add('https://vm.tiktok.com/ZMabc123/');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.consume(), 'https://vm.tiktok.com/ZMabc123/');
    expect(cubit.state.missing, isTrue);

    source.controller.add('https://vm.tiktok.com/ZMxyz789/');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.consumeMissing(), isTrue);
    expect(cubit.state.pending, 'https://vm.tiktok.com/ZMxyz789/');
    await cubit.close();
  });
}

class _MissingSource extends _Source implements MissingLinkSource {
  final StreamController<void> missingController = StreamController.broadcast();

  @override
  Stream<void> get missing => missingController.stream;
}
