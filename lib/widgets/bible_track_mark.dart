import 'package:flutter/material.dart';

/// Exact paths, colors, and transform from assets/icon/bible-track-icon.svg.
/// Fixed brand colors keep the sprout and pages legible in either app theme.
class BibleTrackMark extends CustomPainter {
  const BibleTrackMark({this.background = true});

  final bool background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1024, size.height / 1024);
    if (background) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1024, 1024),
        Paint()..color = const Color(0xFF0F5C3F),
      );
    }
    // <g transform="translate(32.0,20.0) scale(6.0)">
    canvas.translate(32, 20);
    canvas.scale(6);

    final pages = Paint()..color = const Color(0xFFF6F1E4);
    // M80 122 C66 112 46 110 28 114 L28 88 C46 84 66 86 80 96 Z
    canvas.drawPath(
      Path()
        ..moveTo(80, 122)
        ..cubicTo(66, 112, 46, 110, 28, 114)
        ..lineTo(28, 88)
        ..cubicTo(46, 84, 66, 86, 80, 96)
        ..close(),
      pages,
    );
    // M80 122 C94 112 114 110 132 114 L132 88 C114 84 94 86 80 96 Z
    canvas.drawPath(
      Path()
        ..moveTo(80, 122)
        ..cubicTo(94, 112, 114, 110, 132, 114)
        ..lineTo(132, 88)
        ..cubicTo(114, 84, 94, 86, 80, 96)
        ..close(),
      pages,
    );
    // M28 119 C46 115 66 117 80 127 C94 117 114 115 132 119
    canvas.drawPath(
      Path()
        ..moveTo(28, 119)
        ..cubicTo(46, 115, 66, 117, 80, 127)
        ..cubicTo(94, 117, 114, 115, 132, 119),
      Paint()
        ..color = const Color(0xFFCFC6AE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    // M80 97 L80 121
    canvas.drawPath(
      Path()
        ..moveTo(80, 97)
        ..lineTo(80, 121),
      Paint()
        ..color = const Color(0xFFCFC6AE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // M80 98 L80 62
    canvas.drawPath(
      Path()
        ..moveTo(80, 98)
        ..lineTo(80, 62),
      Paint()
        ..color = const Color(0xFF7BC47F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    // M80 70 C58 70 44 58 41 40 C62 40 78 50 80 70 Z
    canvas.drawPath(
      Path()
        ..moveTo(80, 70)
        ..cubicTo(58, 70, 44, 58, 41, 40)
        ..cubicTo(62, 40, 78, 50, 80, 70)
        ..close(),
      Paint()..color = const Color(0xFF4CAF6A),
    );
    // M80 64 C102 64 116 50 119 32 C98 32 82 42 80 64 Z
    canvas.drawPath(
      Path()
        ..moveTo(80, 64)
        ..cubicTo(102, 64, 116, 50, 119, 32)
        ..cubicTo(98, 32, 82, 42, 80, 64)
        ..close(),
      Paint()..color = const Color(0xFF7BC47F),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(BibleTrackMark oldDelegate) =>
      oldDelegate.background != background;
}
