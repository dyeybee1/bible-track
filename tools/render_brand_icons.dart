// Regenerate native icons first: dart run flutter_launcher_icons
// Then: flutter test tools/render_brand_icons.dart
// flutter_launcher_icons uses one web source for both purposes. This step uses
// the supplied maskable artwork explicitly, and never overwrites source assets.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Export PWA icons from the supplied main and maskable PNGs', () async {
    for (final maskable in [false, true]) {
      final suffix = maskable ? '-maskable' : '';
      final codec = await ui.instantiateImageCodec(
        await File('assets/icon/bible-track-icon$suffix.png').readAsBytes(),
      );
      final source = (await codec.getNextFrame()).image;
      for (final pixels in [if (!maskable) 32, 192, 512]) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawImageRect(
          source,
          ui.Rect.fromLTWH(
            0,
            0,
            source.width.toDouble(),
            source.height.toDouble(),
          ),
          ui.Rect.fromLTWH(0, 0, pixels.toDouble(), pixels.toDouble()),
          ui.Paint()..filterQuality = ui.FilterQuality.high,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(pixels, pixels);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final path = pixels == 32
            ? 'web/favicon.png'
            : 'web/icons/Icon$suffix-$pixels.png';
        await File(path).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      }
      source.dispose();
      codec.dispose();
    }
  });
}
