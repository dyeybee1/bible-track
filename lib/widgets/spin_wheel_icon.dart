import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A compact six-wedge wheel with a fixed pointer and center hub.
class SpinWheelIcon extends StatelessWidget {
  const SpinWheelIcon({
    super.key,
    this.size = 28,
    this.color,
    this.outlined = false,
  });

  final double size;
  final Color? color;
  final bool outlined;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _SpinWheelIconPainter(
        color ??
            IconTheme.of(context).color ??
            Theme.of(context).colorScheme.primary,
        outlined,
      ),
    ),
  );
}

class _SpinWheelIconPainter extends CustomPainter {
  _SpinWheelIconPainter(this.color, this.outlined)
    : _stroke = (Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round),
      _fill = (Paint()..color = color);

  final Color color;
  final bool outlined;
  final Paint _stroke;
  final Paint _fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 28, size.height / 28);
    const center = Offset(14, 15);
    const radius = 10.5;
    canvas.drawCircle(center, radius, _stroke);
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * 3,
        center + direction * radius,
        _stroke,
      );
    }
    canvas.drawCircle(center, 2.6, outlined ? _stroke : _fill);
    canvas.drawPath(
      Path()
        ..moveTo(11, 1)
        ..lineTo(17, 1)
        ..lineTo(14, 7)
        ..close(),
      outlined ? _stroke : _fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpinWheelIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.outlined != outlined;
}
