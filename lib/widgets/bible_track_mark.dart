import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The book, check, and progress mark in the shared brand palette.
/// Used by the app and by tools/render_brand_icons.dart for launcher assets.
class BibleTrackMark extends CustomPainter {
  const BibleTrackMark({this.background = true});

  final bool background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1024, size.height / 1024);
    if (background) {
      canvas.drawColor(AppPalette.cream, BlendMode.src);
    }
    final outline = Paint()
      ..color = AppPalette.forest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cover = Path()
      ..moveTo(285, 322)
      ..lineTo(224, 322)
      ..lineTo(224, 724)
      ..lineTo(445, 724)
      ..quadraticBezierTo(505, 773, 565, 724)
      ..lineTo(786, 724)
      ..lineTo(786, 322)
      ..lineTo(720, 322);
    canvas.drawPath(cover, outline);
    final pages = Path()
      ..moveTo(505, 736)
      ..quadraticBezierTo(418, 660, 289, 664)
      ..lineTo(289, 277)
      ..quadraticBezierTo(420, 266, 505, 349)
      ..quadraticBezierTo(588, 266, 720, 277)
      ..lineTo(720, 664)
      ..quadraticBezierTo(590, 660, 505, 736)
      ..moveTo(505, 349)
      ..lineTo(505, 736);
    canvas.drawPath(pages, outline);

    final check = Path()
      ..moveTo(552, 477)
      ..lineTo(596, 522)
      ..lineTo(703, 409);
    canvas.drawPath(
      check,
      Paint()
        ..color = AppPalette.cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = 64
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      check,
      Paint()
        ..color = AppPalette.mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 36
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(422, 553, 392, 80),
        const Radius.circular(40),
      ),
      Paint()..color = AppPalette.cream,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(438, 569, 360, 48),
        const Radius.circular(24),
      ),
      Paint()..color = const Color(0xFFE3DCE9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(438, 569, 220, 48),
        const Radius.circular(24),
      ),
      Paint()..color = AppPalette.mint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(BibleTrackMark oldDelegate) =>
      oldDelegate.background != background;
}
