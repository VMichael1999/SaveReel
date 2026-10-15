import 'package:flutter/material.dart';

/// Marca de SaveTic: un marcador con una flecha hacia abajo.
class SaveticMark extends StatelessWidget {
  const SaveticMark({super.key, this.size = 24, this.color});

  final double size;

  /// Por defecto, el color primario del tema.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'SaveTic',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(color ?? Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Offset p(double x, double y) => Offset(x * s, y * s);
    Radius r(double v) => Radius.circular(v * s);

    final bookmark = Path()
      ..moveTo(6 * s, 3.5 * s)
      ..lineTo(18 * s, 3.5 * s)
      ..arcToPoint(p(19.5, 5), radius: r(1.5))
      ..lineTo(19.5 * s, 20.2 * s)
      ..arcToPoint(p(18.55, 20.69), radius: r(0.6))
      ..lineTo(12 * s, 16.2 * s)
      ..lineTo(5.45 * s, 20.69 * s)
      ..arcToPoint(p(4.5, 20.2), radius: r(0.6))
      ..lineTo(4.5 * s, 5 * s)
      ..arcToPoint(p(6, 3.5), radius: r(1.5))
      ..close();

    final arrow = Path()
      ..moveTo(12 * s, 7.2 * s)
      ..lineTo(12 * s, 12.8 * s)
      ..moveTo(9.3 * s, 10.3 * s)
      ..lineTo(12 * s, 13 * s)
      ..lineTo(14.7 * s, 10.3 * s);

    canvas.drawPath(bookmark, paint);
    canvas.drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}
