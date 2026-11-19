import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/library_fixture.dart';

class _CountingPainter extends CustomPainter {
  _CountingPainter(this.delegate);
  final CustomPainter delegate;
  int paints = 0;

  @override
  void paint(Canvas canvas, Size size) {
    paints++;
    delegate.paint(canvas, size);
  }

  @override
  bool shouldRepaint(_CountingPainter oldDelegate) => true;
}

void main() {
  late LibraryFixture fixture;
  setUpAll(loadLibraryFonts);
  setUp(() async {
    fixture = LibraryFixture();
    await fixture.init();
  });
  tearDown(() => fixture.dispose());

  Finder wheel() => find.byWidgetPredicate(
    (widget) =>
        widget is CustomPaint &&
        widget.painter.runtimeType.toString() == '_WheelPainter',
  );

  testWidgets(
    'idle wheel settles without tickers and scrolling does not repaint its face',
    (tester) async {
      libraryPhone(tester, const Size(390, 640));
      await tester.pumpWidget(fixture.app(spinner: true));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(const Duration(seconds: 10));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);

      final render = tester.renderObject<RenderCustomPaint>(wheel());
      final counter = _CountingPainter(render.painter!);
      render.painter = counter;
      await tester.pump();
      final before = counter.paints;
      expect(before, greaterThan(0));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        counter.paints - before,
        0,
        reason: 'Scrolling must reuse the painted wheel face',
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 120),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('spin transforms a stable wheel face then returns to idle', (
    tester,
  ) async {
    libraryPhone(tester);
    await tester.pumpWidget(fixture.app(spinner: true));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Paikutin'));
    await tester.tap(find.text('Paikutin'));
    await tester.pump();
    final face = tester.widget<CustomPaint>(wheel());
    await tester.pump(const Duration(milliseconds: 800));
    expect(
      tester.widget<CustomPaint>(wheel()),
      same(face),
      reason: 'Only the transform should rebuild on a spin tick',
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(fixture.progress.chaptersReadTotal, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
