import 'package:flutter/material.dart';

import '../utils/video_link.dart';

/// Glifo de cada red, dibujado aquí (no son los logos oficiales): una nota
/// con el desfase cian y rosa para TikTok, y una cámara con el degradado de
/// SaveReel para Instagram.
class NetworkMark extends StatelessWidget {
  const NetworkMark({super.key, required this.network, this.size = 24});

  final VideoNetwork network;
  final double size;

  static String labelOf(VideoNetwork network) => switch (network) {
    VideoNetwork.tiktok => 'TikTok',
    VideoNetwork.instagram => 'Instagram',
  };

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      label: labelOf(network),
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: switch (network) {
          VideoNetwork.tiktok => _TikTokPainter(ink),
          VideoNetwork.instagram => _InstagramPainter(),
        },
      ),
    );
  }
}

Paint _stroke(double s, {Color? color, Shader? shader}) =>
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color ?? const Color(0xFFFFFFFF)
      ..shader = shader;

class _TikTokPainter extends CustomPainter {
  _TikTokPainter(this.ink);

  final Color ink;

  static const Color _cyan = Color(0xFF25F4EE);
  static const Color _pink = Color(0xFFFF4D8D);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;

    void note(Color color, Offset shift) {
      canvas.save();
      canvas.translate(shift.dx * s, shift.dy * s);
      final paint = _stroke(s, color: color);
      final stem =
          Path()
            ..moveTo(14 * s, 4 * s)
            ..lineTo(14 * s, 16 * s)
            ..moveTo(14 * s, 4 * s)
            ..cubicTo(14.4 * s, 7 * s, 16.4 * s, 8.6 * s, 19 * s, 8.8 * s);
      canvas.drawPath(stem, paint);
      canvas.drawCircle(Offset(10.6 * s, 16.4 * s), 3.4 * s, paint);
      canvas.restore();
    }

    note(_cyan, const Offset(-0.9, 0.7));
    note(_pink, const Offset(0.9, -0.7));
    note(ink, Offset.zero);
  }

  @override
  bool shouldRepaint(_TikTokPainter old) => old.ink != ink;
}

class _InstagramPainter extends CustomPainter {
  static const LinearGradient _gradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF8134AF), Color(0xFFFF4D8D), Color(0xFFFF9A3C)],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final shader = _gradient.createShader(Offset.zero & size);
    final paint = _stroke(s, shader: shader);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(3.5 * s, 3.5 * s, 20.5 * s, 20.5 * s),
        Radius.circular(6 * s),
      ),
      paint,
    );
    canvas.drawCircle(Offset(12 * s, 12 * s), 4.2 * s, paint);
    canvas.drawCircle(
      Offset(17.2 * s, 6.8 * s),
      1.15 * s,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_InstagramPainter old) => false;
}
