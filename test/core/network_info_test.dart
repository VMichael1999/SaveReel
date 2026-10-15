import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/helpers/network_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('savetic/network');

  void answer(Future<Object?> Function(MethodCall call)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
  }

  test('devuelve lo que responde la plataforma', () async {
    answer((call) async => call.method == 'isMetered');
    expect(await NetworkInfo.isMetered(), isTrue);

    answer((_) async => false);
    expect(await NetworkInfo.isMetered(), isFalse);
  });

  test(
    'si la plataforma falla o no responde, no bloquea la descarga',
    () async {
      answer((_) async => throw PlatformException(code: 'x'));
      expect(await NetworkInfo.isMetered(), isFalse);

      answer(null); // sin canal: MissingPluginException
      expect(await NetworkInfo.isMetered(), isFalse);

      answer((_) async => null);
      expect(await NetworkInfo.isMetered(), isFalse);
    },
  );
}
