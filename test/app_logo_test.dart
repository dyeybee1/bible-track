import 'dart:io';
import 'dart:ui' as ui;

import 'package:bible_track/widgets/app_header.dart';
import 'package:bible_track/widgets/app_logo.dart';
import 'package:bible_track/widgets/bible_track_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('painted mark matches the supplied launcher artwork', () async {
    final recorder = ui.PictureRecorder();
    const BibleTrackMark().paint(Canvas(recorder), const Size.square(1024));
    final picture = recorder.endRecording();
    final painted = await picture.toImage(1024, 1024);
    final codec = await ui.instantiateImageCodec(
      await File('assets/icon/bible-track-icon.png').readAsBytes(),
    );
    final reference = (await codec.getNextFrame()).image;
    final actual = (await painted.toByteData())!.buffer.asUint8List();
    final expected = (await reference.toByteData())!.buffer.asUint8List();
    expect(painted.width, reference.width);
    expect(painted.height, reference.height);
    var differentPixels = 0;
    for (var pixel = 0; pixel < actual.length; pixel += 4) {
      if (List.generate(4, (channel) => channel).any(
        (channel) =>
            (actual[pixel + channel] - expected[pixel + channel]).abs() > 16,
      )) {
        differentPixels++;
      }
    }
    // Allow rasterizer antialiasing differences along the exact SVG curves.
    expect(differentPixels / (1024 * 1024), lessThan(0.01));
    if (const bool.fromEnvironment('CAPTURE_BRAND')) {
      await Directory('build/brand').create(recursive: true);
      final png = await painted.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/brand/mark.png',
      ).writeAsBytes(png!.buffer.asUint8List());
    }
    painted.dispose();
    reference.dispose();
    picture.dispose();
    codec.dispose();
  });

  for (final brightness in Brightness.values) {
    testWidgets('$brightness logos keep sizes, semantics, and header actions', (
      tester,
    ) async {
      var taps = 0;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Builder(
            builder: (context) => Scaffold(
              appBar: appHeader(
                context,
                title: 'Bible Track',
                root: true,
                actions: [
                  IconButton(
                    onPressed: () => taps++,
                    icon: const Icon(Icons.settings),
                  ),
                ],
              ),
              body: const Column(
                children: [
                  AppLogo(size: 40),
                  AppLogo(size: 80),
                  AppLogo(size: 88),
                  AppLogo(),
                ],
              ),
            ),
          ),
        ),
      );
      final logos = find.byType(AppLogo);
      expect(logos, findsNWidgets(5));
      for (final element in logos.evaluate()) {
        final logo = element.widget as AppLogo;
        expect(tester.getSize(find.byWidget(logo)), Size.square(logo.size));
        if (logo.size != 32) {
          expect(tester.getSemantics(find.byWidget(logo)).label, 'Bible Track');
        }
      }
      final headerLogo = find.descendant(
        of: find.byType(AppBar),
        matching: logos,
      );
      expect(tester.getSize(headerLogo), const Size.square(32));
      expect(
        tester.getTopLeft(find.text('Bible Track')).dx -
            tester.getTopRight(headerLogo).dx,
        8,
      );
      await tester.tap(find.byIcon(Icons.settings));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
