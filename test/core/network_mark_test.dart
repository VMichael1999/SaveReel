import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/core/utils/video_link.dart';
import 'package:savetic/src/core/widgets/network_mark.dart';

void main() {
  for (final network in VideoNetwork.values) {
    testWidgets('el glifo de $network se dibuja y tiene su nombre', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Center(child: NetworkMark(network: network, size: 48)),
        ),
      );
      expect(find.bySemanticsLabel(NetworkMark.labelOf(network)), findsOne);
      expect(tester.takeException(), isNull);
    });
  }
}
