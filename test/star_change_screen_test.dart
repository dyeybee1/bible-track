import 'dart:io';
import 'dart:typed_data';

import 'package:bible_track/data/books_data.dart';
import 'package:bible_track/data/progress_controller.dart';
import 'package:bible_track/data/rank_system.dart';
import 'package:bible_track/data/settings_controller.dart';
import 'package:bible_track/features/rank/star_change_screen.dart';
import 'package:bible_track/l10n/strings.dart';
import 'package:bible_track/settings_scope.dart';
import 'package:bible_track/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test helpers
// ─────────────────────────────────────────────────────────────────────────────

RankInfo _rank(int stars) => rankForStars(stars);

/// Pumps past the full animation: 1500 ms main controller + 200 ms close timer.
/// Adds an extra frame so setState(_canClose = true) propagates.
Future<void> _pumpFull(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 400));
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late Directory temp;
  late SettingsController settings;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('star_change_');
    Hive.init(temp.path);
    settings = SettingsController(
      await Hive.openBox<dynamic>('settings', bytes: Uint8List(0)),
    );
    // Use Filipino so rankName() returns Filipino tier names (Binhi, Usbong …)
    settings.setLanguage('fil');
  });

  tearDown(() async {
    settings.dispose();
    await Hive.close();
    await temp.delete(recursive: true);
  });

  Widget app(Widget home) => SettingsScope(
    controller: settings,
    child: MaterialApp(theme: lightTheme, home: home),
  );

  // Star-change animation states.

  Finder rowIcons(IconData icon) => find.descendant(
    of: find.byKey(const ValueKey('animated-star-row')),
    matching: find.byIcon(icon),
  );

  for (final (before, after) in [(0, 1), (2, 3), (3, 2), (1, 0)]) {
    final gain = after > before;
    testWidgets('same division $before -> $after flies or fades', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          StarChangeScreen(
            before: _rank(before),
            after: _rank(after),
            maxStarsEver: 50,
            isGain: gain,
          ),
        ),
      );
      expect(rowIcons(Icons.star_rounded), findsNWidgets(before));
      await tester.pump(const Duration(milliseconds: 450));
      if (gain) {
        expect(find.byKey(const ValueKey('flying-star')), findsOneWidget);
        expect(rowIcons(Icons.star_rounded), findsNWidgets(before));
      } else {
        final fadingStar = find
            .ancestor(
              of: rowIcons(Icons.star_rounded).last,
              matching: find.byType(Opacity),
            )
            .first;
        final opacity = tester.widget<Opacity>(fadingStar).opacity;
        expect(opacity, greaterThan(0));
        expect(opacity, lessThan(1));
      }
      expect(
        find.byKey(const ValueKey('division-promotion-burst')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('tier-promotion-burst')), findsNothing);
      await _pumpFull(tester);
      expect(rowIcons(Icons.star_rounded), findsNWidgets(after));
      expect(rowIcons(Icons.star_outline_rounded), findsNWidgets(4 - after));
      expect(find.text(gain ? '+1 ★' : '-1 ★'), findsOneWidget);
      expect(find.textContaining('Umakyat'), findsNothing);
      expect(find.textContaining('Bumaba'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  }

  for (final (before, after) in [
    (4, 5),
    (5, 4),
    (12, 13),
    (13, 12),
    (24, 25),
    (25, 24),
    (96, 97),
    (97, 96),
    (116, 117),
    (117, 116),
    (136, 137),
    (137, 136),
  ]) {
    final gain = after > before;
    final oldRank = _rank(before);
    final newRank = _rank(after);
    final tierChange = oldRank.tier != newRank.tier;
    testWidgets('rank transition $before -> $after', (tester) async {
      await tester.pumpWidget(
        app(
          StarChangeScreen(
            before: oldRank,
            after: newRank,
            maxStarsEver: before > after ? before : after,
            isGain: gain,
          ),
        ),
      );
      if (!oldRank.isTopTier) {
        expect(rowIcons(Icons.star_rounded), findsNWidgets(gain ? 4 : 1));
        expect(
          rowIcons(Icons.star_outline_rounded),
          findsNWidgets(gain ? 0 : 3),
        );
      }
      await tester.pump(const Duration(milliseconds: 450));
      expect(
        find.byKey(const ValueKey('flying-star')),
        gain ? findsOneWidget : findsNothing,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(
          ValueKey(
            tierChange ? 'tier-promotion-burst' : 'division-promotion-burst',
          ),
        ),
        gain ? findsOneWidget : findsNothing,
      );
      if (!gain) {
        expect(
          find.byKey(const ValueKey('tier-promotion-burst')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('division-promotion-burst')),
          findsNothing,
        );
      }
      await _pumpFull(tester);
      final name = const Strings('fil').rankName(newRank);
      expect(
        find.text(gain ? 'Umakyat ka sa $name!' : 'Bumaba ka sa $name'),
        findsOneWidget,
      );
      if (newRank.isTopTier) {
        expect(find.text('1 bituin'), findsOneWidget);
        expect(find.byKey(const ValueKey('animated-star-row')), findsNothing);
      } else {
        expect(rowIcons(Icons.star_rounded), findsNWidgets(gain ? 1 : 4));
        expect(
          rowIcons(Icons.star_outline_rounded),
          findsNWidgets(gain ? 3 : 0),
        );
      }
      expect(
        find.textContaining('Pinakamataas'),
        gain ? findsNothing : findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  }

  for (final (before, after) in [(1333, 1334), (1334, 1333)]) {
    testWidgets('top-tier count $before -> $after ignores a higher peak', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          StarChangeScreen(
            before: _rank(before),
            after: _rank(after),
            maxStarsEver: 5000,
            isGain: after > before,
          ),
        ),
      );
      expect(find.text('${before - 136} ★'), findsOneWidget);
      await _pumpFull(tester);
      expect(find.text('${after - 136} ★'), findsOneWidget);
      expect(find.byKey(const ValueKey('animated-star-row')), findsNothing);
      expect(find.textContaining('Umakyat'), findsNothing);
      expect(find.textContaining('Bumaba'), findsNothing);
    });
  }

  testWidgets('highest rank reassurance is hidden within the same rank', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        StarChangeScreen(
          before: _rank(3),
          after: _rank(2),
          maxStarsEver: 4,
          isGain: false,
        ),
      ),
    );
    await _pumpFull(tester);
    expect(find.textContaining('Pinakamataas'), findsNothing);
  });

  testWidgets('reduced motion immediately shows the new rank and close hint', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    await tester.pumpWidget(
      app(
        StarChangeScreen(
          before: _rank(96),
          after: _rank(97),
          maxStarsEver: 97,
          isGain: true,
        ),
      ),
    );
    expect(rowIcons(Icons.star_rounded), findsOneWidget);
    expect(rowIcons(Icons.star_outline_rounded), findsNWidgets(3));
    expect(find.text('Umakyat ka sa Apostol V!'), findsOneWidget);
    expect(find.byKey(const ValueKey('flying-star')), findsNothing);
    expect(find.byKey(const ValueKey('tier-promotion-burst')), findsNothing);
    final hint = find.ancestor(
      of: find.text('Pindutin para magpatuloy'),
      matching: find.byType(FadeTransition),
    );
    expect(tester.widget<FadeTransition>(hint.first).opacity.value, 1);
  });

  group('StarChangeScreen tap behaviour', () {
    testWidgets('tap before animation finishes does NOT pop', (tester) async {
      // Push the screen on top of a base scaffold
      late BuildContext navCtx;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (ctx) {
              navCtx = ctx;
              return const Scaffold(body: Text('base'));
            },
          ),
        ),
      );
      unawaited(
        pushStarChangeScreen(
          context: navCtx,
          before: _rank(0),
          after: _rank(1),
          maxStarsEver: 1,
          isGain: true,
        ),
      );
      await tester.pump(); // let the route start
      await tester.pump(const Duration(milliseconds: 300)); // enter animation
      // Tap at 400 ms total — main animation still running (1500 ms)
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(const Offset(200, 400));
      await tester.pump(const Duration(milliseconds: 100));
      // Screen still showing
      expect(find.byType(StarChangeScreen), findsOneWidget);
      // Drain pending timer so teardown is clean
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    });

    testWidgets('tap after animation finishes pops the screen', (tester) async {
      // Use a NavigatorObserver to verify pop() is called without relying on
      // animation-timing-sensitive widget-tree checks.
      var popCount = 0;
      final observer = _CountingObserver(onPop: () => popCount++);

      late BuildContext navCtx;
      await tester.pumpWidget(
        SettingsScope(
          controller: settings,
          child: MaterialApp(
            theme: lightTheme,
            navigatorObservers: [observer],
            home: Builder(
              builder: (ctx) {
                navCtx = ctx;
                return const Scaffold(body: Text('base'));
              },
            ),
          ),
        ),
      );
      unawaited(
        pushStarChangeScreen(
          context: navCtx,
          before: _rank(0),
          after: _rank(1),
          maxStarsEver: 1,
          isGain: true,
        ),
      );
      await tester
          .pump(); // register route, build StarChangeScreen, initState runs
      // The route transition takes 300 ms. During this transition TickerMode
      // may be disabled for the new route's tickers.
      await tester.pump(
        const Duration(milliseconds: 300),
      ); // route fully entered
      // Now _mainCtrl tickers are active. Advance past the 1500 ms animation
      // and the 200 ms close-timer.
      await tester.pump(
        const Duration(milliseconds: 1500),
      ); // main anim completes
      await tester.pump(const Duration(milliseconds: 200)); // close timer fires
      await tester.pump(); // flush setState(_canClose = true)
      // Tap anywhere — _canClose is now true, _tryClose() calls pop().
      await tester.tap(find.byType(StarChangeScreen));
      await tester.pump(); // process the tap
      // pop() should have been called once.
      expect(popCount, 1);
    });
  });

  // ── screen does NOT open on non-user-initiated events ─────────────────────

  group('StarChangeScreen does NOT open on', () {
    late Directory progTemp;
    late ProgressController progress;

    setUp(() async {
      progTemp = await Directory.systemTemp.createTemp('progress_');
      final box = await Hive.openBox<dynamic>(
        'progress_noscreen',
        bytes: Uint8List(0),
      );
      progress = ProgressController(box);
    });

    tearDown(() async {
      progress.dispose();
      await progTemp.delete(recursive: true);
    });

    testWidgets('applyMerge', (tester) async {
      await tester.pumpWidget(app(const Scaffold(body: Text('home'))));
      // applyMerge should never open StarChangeScreen
      progress.applyMerge(0, {}, progress.exportRecords());
      await tester.pumpAndSettle();
      expect(find.byType(StarChangeScreen), findsNothing);
    });

    testWidgets('startNewCycle', (tester) async {
      progress.markUpTo(allBooks.first, allBooks.first.totalChapters);
      await tester.pumpWidget(app(const Scaffold(body: Text('home'))));
      progress.startNewCycle();
      await tester.pumpAndSettle();
      expect(find.byType(StarChangeScreen), findsNothing);
    });
  });
}

// ignore: avoid_void_async
void unawaited(Future<void> f) {}

class _CountingObserver extends NavigatorObserver {
  _CountingObserver({required this.onPop});
  final VoidCallback onPop;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPop();
  }
}
