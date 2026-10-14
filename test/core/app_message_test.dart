import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/core/utils/app_enums.dart';
import 'package:savetic/src/core/widgets/app_message.dart';

Future<BuildContext> _pump(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Builder(
        builder: (c) {
          ctx = c;
          return const Scaffold();
        },
      ),
    ),
  );
  return ctx;
}

/// El aviso entra tras unos cuadros: se avanza de a poco.
Future<void> _showUp(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('muestra el mensaje y se cierra solo', (tester) async {
    final ctx = await _pump(tester);
    showAppMessage(ctx, msg: 'Guardado', type: MessageType.success);
    await _showUp(tester);
    expect(find.text('Guardado'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Guardado'), findsNothing);
  });

  testWidgets('cada tipo usa su ícono', (tester) async {
    final ctx = await _pump(tester);
    showAppMessage(ctx, msg: 'Falló', type: MessageType.error);
    await _showUp(tester);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    showAppMessage(ctx, msg: 'Aviso', type: MessageType.info);
    await _showUp(tester);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
  });

  testWidgets('un aviso nuevo reemplaza al anterior', (tester) async {
    final ctx = await _pump(tester);
    showAppMessage(ctx, msg: 'Uno', type: MessageType.info);
    await _showUp(tester);
    showAppMessage(ctx, msg: 'Dos', type: MessageType.info);
    await _showUp(tester);
    await _showUp(tester);
    expect(find.text('Uno'), findsNothing);
    expect(find.text('Dos'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
  });

  testWidgets('la acción llama al callback y cierra el aviso', (tester) async {
    final ctx = await _pump(tester);
    var taps = 0;
    showAppMessage(
      ctx,
      msg: 'Listo',
      type: MessageType.success,
      actionLabel: 'Reproducir',
      onAction: () => taps++,
    );
    await _showUp(tester);
    await tester.tap(find.text('Reproducir'));
    await tester.pump();
    expect(taps, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Listo'), findsNothing);
    await tester.pump(const Duration(seconds: 7));
  });

  testWidgets('se descarta deslizando hacia arriba', (tester) async {
    final ctx = await _pump(tester);
    showAppMessage(ctx, msg: 'Deslizame', type: MessageType.info);
    await _showUp(tester);
    await tester.drag(find.text('Deslizame'), const Offset(0, -300));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Deslizame'), findsNothing);
    await tester.pump(const Duration(seconds: 7));
  });
}
