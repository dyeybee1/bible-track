// Run with: flutter test tools/render_brand_icons.dart
// Then run: dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bible_track/widgets/bible_track_mark.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Export the shared vector brand mark as launcher source assets',
    () async {
      for (final background in [true, false]) {
        final recorder = ui.PictureRecorder();
        const size = Size.square(1024);
        BibleTrackMark(background: background).paint(Canvas(recorder), size);
        final picture = recorder.endRecording();
        final image = await picture.toImage(1024, 1024);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final suffix = background ? '' : '-foreground';
        await File(
          'assets/icon/bible-track-icon$suffix-1024.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      }
    },
  );
}
