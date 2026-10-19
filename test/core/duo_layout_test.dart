import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/layout/duo_layout.dart';

void main() {
  group('tamaños reales', () {
    test('iPhone normal, vertical y horizontal, queda en normal', () {
      expect(duoLayoutFor(const Size(393, 852)), DuoLayout.normal);
      expect(duoLayoutFor(const Size(852, 393)), DuoLayout.normal);
    });

    test('otros iPhone y Android comunes quedan en normal', () {
      for (final size in const [
        Size(375, 667), // iPhone SE
        Size(390, 844),
        Size(430, 932), // iPhone Pro Max
        Size(360, 800), // Android típico
        Size(412, 915),
        Size(667, 375),
        Size(932, 430), // Pro Max en horizontal
        Size(915, 412), // Android en horizontal
      ]) {
        expect(duoLayoutFor(size), DuoLayout.normal, reason: '$size');
      }
    });

    test('pantalla exterior cerrada', () {
      expect(duoLayoutFor(const Size(466, 678)), DuoLayout.closed);
    });

    test('pantalla interior abierta', () {
      expect(duoLayoutFor(const Size(951, 669)), DuoLayout.openLandscape);
      expect(duoLayoutFor(const Size(669, 951)), DuoLayout.openPortrait);
    });

    test('Split View, la mitad de la interior, cae en cerrado', () {
      expect(duoLayoutFor(const Size(475, 669)), DuoLayout.closed);
    });
  });

  group('bordes de cada rango', () {
    test('cerrado: ancho 420 a 520', () {
      expect(duoLayoutFor(const Size(420, 600)), DuoLayout.closed);
      expect(duoLayoutFor(const Size(419, 600)), DuoLayout.normal);
      expect(duoLayoutFor(const Size(520, 700)), DuoLayout.closed);
      expect(duoLayoutFor(const Size(521, 700)), DuoLayout.normal);
    });

    test('cerrado: relación alto/ancho de 1.3 a 1.6', () {
      expect(duoLayoutFor(const Size(500, 650)), DuoLayout.closed);
      expect(duoLayoutFor(const Size(500, 649)), DuoLayout.normal);
      expect(duoLayoutFor(const Size(500, 800)), DuoLayout.closed);
      expect(duoLayoutFor(const Size(500, 801)), DuoLayout.normal);
    });

    test('abierto en horizontal: ancho desde 840 y mayor que el alto', () {
      expect(duoLayoutFor(const Size(840, 600)), DuoLayout.openLandscape);
      expect(duoLayoutFor(const Size(839, 600)), DuoLayout.normal);
      expect(duoLayoutFor(const Size(840, 840)), DuoLayout.normal);
    });

    test('abierto en vertical: ancho desde 600 y menor que el alto', () {
      expect(duoLayoutFor(const Size(600, 900)), DuoLayout.openPortrait);
      expect(duoLayoutFor(const Size(599, 900)), DuoLayout.normal);
      expect(duoLayoutFor(const Size(600, 600)), DuoLayout.normal);
    });

    test('abierto: un teléfono alargado no cuenta, aunque sea ancho', () {
      expect(duoLayoutFor(const Size(900, 500)), DuoLayout.normal);
      expect(duoLayoutFor(const Size(960, 600)), DuoLayout.openLandscape);
      expect(duoLayoutFor(const Size(600, 1000)), DuoLayout.normal);
      expect(duoLayoutFor(const Size(600, 960)), DuoLayout.openPortrait);
    });

    test('tamaños vacíos o inválidos quedan en normal', () {
      expect(duoLayoutFor(Size.zero), DuoLayout.normal);
      expect(duoLayoutFor(const Size(0, 800)), DuoLayout.normal);
    });
  });
}
