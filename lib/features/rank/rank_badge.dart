import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/rank_system.dart';
import '../../settings_scope.dart';

/// All tier artwork uses one shield, replaceable with custom artwork later.
class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank, this.size = 48});
  final RankInfo rank;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.s.rankName(rank),
    image: true,
    child: ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _ShieldPainter(
            tierIndex: rankLadder.indexOf(rank.tier),
            milestoneLevel: rank.milestone == null
                ? 0
                : rankMilestones.indexOf(rank.milestone!) + 1,
            dark: Theme.of(context).brightness == Brightness.dark,
          ),
        ),
      ),
    ),
  );
}

class _ShieldPainter extends CustomPainter {
  const _ShieldPainter({
    required this.tierIndex,
    required this.dark,
    required this.milestoneLevel,
  });
  final int tierIndex;
  final bool dark;
  final int milestoneLevel;
  static const _colors = [
    Color(0xFF52766B),
    Color(0xFF087F8C),
    Color(0xFF2563BB),
    Color(0xFF4F46B6),
    Color(0xFF8745B0),
    Color(0xFFA9630B),
    Color(0xFFE9AD19),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final color = Color.lerp(
      _colors[tierIndex],
      const Color(0xFFFFE17B),
      milestoneLevel * .1,
    )!;
    final edge = Color.lerp(color, Colors.white, dark ? .38 : .06)!;
    final ink = tierIndex == rankLadder.length - 1
        ? const Color(0xFF573400)
        : Colors.white;
    if (tierIndex == rankLadder.length - 1) {
      canvas.drawCircle(
        const Offset(50, 47),
        43,
        Paint()
          ..color = color.withValues(
            alpha: (dark ? .19 : .12) + milestoneLevel * .035,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 + milestoneLevel * 1.5,
      );
    }
    final shield = Path()
      ..moveTo(50, 7)
      ..lineTo(84, 19)
      ..lineTo(81, 55)
      ..cubicTo(79, 72, 65, 85, 50, 93)
      ..cubicTo(35, 85, 21, 72, 19, 55)
      ..lineTo(16, 19)
      ..close();
    canvas.drawPath(
      shield,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, dark ? .12 : .2)!,
            Color.lerp(color, Colors.black, dark ? .22 : .12)!,
          ],
        ).createShader(const Rect.fromLTWH(16, 7, 68, 86)),
    );
    canvas.drawPath(
      shield,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = ink;
    switch (tierIndex) {
      case 0: // magnifier
        canvas.drawCircle(const Offset(46, 43), 13, stroke);
        canvas.drawLine(const Offset(56, 54), const Offset(68, 66), stroke);
      case 1: // alternating footprints
        canvas.save();
        canvas.rotate(-.15);
        canvas.drawOval(const Rect.fromLTWH(23, 36, 11, 20), fill);
        canvas.drawOval(const Rect.fromLTWH(24, 59, 9, 7), fill);
        canvas.drawOval(const Rect.fromLTWH(45, 29, 11, 20), fill);
        canvas.drawOval(const Rect.fromLTWH(46, 52, 9, 7), fill);
        canvas.restore();
      case 2: // open book
        canvas.drawPath(
          Path()
            ..moveTo(50, 65)
            ..lineTo(50, 36)
            ..quadraticBezierTo(40, 29, 29, 34)
            ..lineTo(29, 61)
            ..quadraticBezierTo(40, 57, 50, 65)
            ..quadraticBezierTo(60, 57, 71, 61)
            ..lineTo(71, 34)
            ..quadraticBezierTo(60, 29, 50, 36),
          stroke,
        );
      case 3: // compass
        canvas.drawCircle(const Offset(50, 48), 22, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(59, 35)
            ..lineTo(54, 53)
            ..lineTo(41, 61)
            ..lineTo(46, 43)
            ..close(),
          fill,
        );
      case 4: // crescent and star
        canvas.drawPath(
          Path()
            ..moveTo(53, 28)
            ..cubicTo(23, 29, 25, 66, 52, 67)
            ..quadraticBezierTo(61, 68, 67, 59)
            ..cubicTo(44, 66, 37, 40, 53, 28)
            ..close(),
          fill,
        );
        _star(canvas, const Offset(64, 36), 8, fill);
      case 5: // rolled scroll
        canvas.drawPath(
          Path()
            ..moveTo(34, 33)
            ..lineTo(62, 33)
            ..quadraticBezierTo(73, 33, 70, 42)
            ..lineTo(61, 42)
            ..lineTo(61, 64)
            ..quadraticBezierTo(61, 72, 49, 68)
            ..lineTo(31, 68)
            ..quadraticBezierTo(22, 68, 27, 59)
            ..lineTo(36, 59)
            ..lineTo(36, 37)
            ..quadraticBezierTo(36, 29, 29, 33),
          stroke,
        );
        canvas.drawLine(const Offset(43, 44), const Offset(54, 44), stroke);
        canvas.drawLine(const Offset(43, 52), const Offset(54, 52), stroke);
      case 6: // sun burst, with a shared silhouette across milestones
        if (milestoneLevel >= 2) {
          canvas.drawCircle(
            const Offset(50, 48),
            29,
            Paint()
              ..color = ink.withValues(alpha: .5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        if (milestoneLevel >= 1) {
          _star(canvas, const Offset(29, 28), 4, fill);
          _star(canvas, const Offset(72, 66), 4, fill);
        }
        canvas.drawCircle(const Offset(50, 48), 11, fill);
        final rays = 8 + milestoneLevel * 4;
        for (var i = 0; i < rays; i++) {
          final a = i * math.pi * 2 / rays;
          canvas.drawLine(
            Offset(50 + math.cos(a) * 17, 48 + math.sin(a) * 17),
            Offset(50 + math.cos(a) * 23, 48 + math.sin(a) * 23),
            stroke,
          );
        }
    }
    canvas.restore();
  }

  void _star(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 - math.pi / 2;
      final r = i.isEven ? radius : radius * .35;
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path..close(), paint);
  }

  @override
  bool shouldRepaint(_ShieldPainter oldDelegate) =>
      tierIndex != oldDelegate.tierIndex ||
      dark != oldDelegate.dark ||
      milestoneLevel != oldDelegate.milestoneLevel;
}
