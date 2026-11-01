import 'dart:io';
import 'dart:typed_data';

import 'package:bible_track/data/books_data.dart';
import 'package:bible_track/data/progress_controller.dart';
import 'package:bible_track/data/rank_system.dart';
import 'package:bible_track/data/settings_controller.dart';
import 'package:bible_track/features/rank/star_change_screen.dart';
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
  await tester.pump(const Duration(milliseconds: 1700));
  await tester.pump(); // flush setState
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

  // ── pure rank tests ────────────────────────────────────────────────────────

  group('rankForStars', () {
    test('0 stars → Binhi III, 0/10', () {
      final r = _rank(0);
      expect(r.tier.nameFil, 'Binhi');
      expect(r.division, RankDivision.iii);
      expect(r.starsInDivision, 0);
      expect(r.starsForDivision, 10);
    });

    test('10 stars → Binhi II, 0/10', () {
      final r = _rank(10);
      expect(r.division, RankDivision.ii);
      expect(r.starsInDivision, 0);
    });

    test('29 stars → Binhi I, 9/10', () {
      final r = _rank(29);
      expect(r.division, RankDivision.i);
      expect(r.starsInDivision, 9);
    });

    test('isHigherThan: Binhi II > Binhi III', () {
      expect(_rank(10).isHigherThan(_rank(0)), isTrue);
      expect(_rank(0).isHigherThan(_rank(10)), isFalse);
    });

    test('isHigherThan: Usbong > Binhi', () {
      expect(_rank(30).isHigherThan(_rank(0)), isTrue);
    });

    test('top tier has null division', () {
      // Salita ng Buhay starts after all lower tiers:
      // Binhi:30 + Usbong:45 + Halaman:75 + Puno:120 + Ubasan:180 +
      // Alagad:270 + Propeta:360 = 1080
      final r = _rank(1080);
      expect(r.division, isNull);
      expect(r.tier.nameFil, 'Salita ng Buhay');
    });
  });

  // ── StarChangeScreen render tests ──────────────────────────────────────────

  group('StarChangeScreen renders', () {
    testWidgets('same-division gain shows +1 ★', (tester) async {
      await tester.pumpWidget(app(StarChangeScreen(
        before: _rank(0),
        after: _rank(1),
        maxStarsEver: 1,
        isGain: true,
      )));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('+1'), findsOneWidget);
      // Drain any pending timer so teardown is clean.
      await _pumpFull(tester);
    });

    testWidgets('same-division loss shows -1 ★', (tester) async {
      await tester.pumpWidget(app(StarChangeScreen(
        before: _rank(1),
        after: _rank(0),
        maxStarsEver: 1,
        isGain: false,
      )));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('-1'), findsOneWidget);
      await _pumpFull(tester);
    });

    testWidgets('division up: shows new division in rank name area', (tester) async {
      // 9→10: Binhi III (9/10) → Binhi II (0/10). _kind = rankUp.
      await tester.pumpWidget(app(StarChangeScreen(
        before: _rank(9),
        after: _rank(10),
        maxStarsEver: 10,
        isGain: true,
      )));
      await _pumpFull(tester);
      // lang=fil: rankName(Binhi II) = "Binhi II"; appears in rank name widget
      // and in the rank-up message "Umakyat ka sa Binhi II!"
      expect(find.textContaining('Binhi II'), findsWidgets);
    });

    testWidgets('division down: shows lower division name', (tester) async {
      // 10→9: Binhi II → Binhi III. _kind = rankDown.
      await tester.pumpWidget(app(StarChangeScreen(
        before: _rank(10),
        after: _rank(9),
        maxStarsEver: 10,
        isGain: false,
      )));
      await _pumpFull(tester);
      // rankName(Binhi III) = "Binhi III"; appears in rank name and rank-down message
      expect(find.textContaining('Binhi III'), findsWidgets);
    });

    testWidgets('tier up: message contains new tier name', (tester) async {
      // 29→30: Binhi I → Usbong III. _kind = rankUp.
      await tester.pumpWidget(app(StarChangeScreen(
        before: _rank(29),
        after: _rank(30),
        maxStarsEver: 30,
        isGain: true,
      )));
      await _pumpFull(tester);
      // "Umakyat ka sa Usbong III!" contains "Usbong"
      expect(find.textContaining('Usbong'), findsWidgets);
    });

    testWidgets('tier down: message contains lower tier name', (tester) async {
      // 30→29: Usbong III → Binhi I. _kind = rankDown.
      await tester.pumpWidget(app(StarChangeScreen(
        before: _rank(30),
        after: _rank(29),
        maxStarsEver: 30,
        isGain: false,
      )));
      await _pumpFull(tester);
      // "Bumaba ka sa Binhi I" contains "Binhi"
      expect(find.textContaining('Binhi'), findsWidgets);
    });

    testWidgets('top-tier gain shows star count', (tester) async {
      await tester.pumpWidget(app(StarChangeScreen(
        before: _rank(1080),
        after: _rank(1081),
        maxStarsEver: 1081,
        isGain: true,
      )));
      await _pumpFull(tester);
      expect(find.textContaining('1081'), findsWidgets);
    });

    testWidgets('top-tier loss shows star count', (tester) async {
      await tester.pumpWidget(app(StarChangeScreen(
        before: _rank(1081),
        after: _rank(1080),
        maxStarsEver: 1081,
        isGain: false,
      )));
      await _pumpFull(tester);
      expect(find.textContaining('1080'), findsWidgets);
    });

    testWidgets(
        '"highest rank still" line shows on loss when max > current',
        (tester) async {
      // Lose a star: now 0 (Binhi III), but maxStarsEver=10 (Binhi II)
      await tester.pumpWidget(app(StarChangeScreen(
        before: _rank(1),
        after: _rank(0),
        maxStarsEver: 10,
        isGain: false,
      )));
      await _pumpFull(tester);
      // Filipino string contains 'Pinakamataas'
      expect(find.textContaining('Pinakamataas'), findsOneWidget);
    });

    testWidgets(
        '"highest rank still" line hidden when max == current',
        (tester) async {
      // Gain a star: current == max, no highest-rank line
      await tester.pumpWidget(app(StarChangeScreen(
        before: _rank(0),
        after: _rank(1),
        maxStarsEver: 1,
        isGain: true,
      )));
      await _pumpFull(tester);
      expect(find.textContaining('Pinakamataas'), findsNothing);
    });
  });

  // ── tap-before / tap-after animation ──────────────────────────────────────

  group('StarChangeScreen tap behaviour', () {
    testWidgets('tap before animation finishes does NOT pop', (tester) async {
      // Push the screen on top of a base scaffold
      late BuildContext navCtx;
      await tester.pumpWidget(app(Builder(
        builder: (ctx) {
          navCtx = ctx;
          return const Scaffold(body: Text('base'));
        },
      )));
      unawaited(pushStarChangeScreen(
        context: navCtx,
        before: _rank(0),
        after: _rank(1),
        maxStarsEver: 1,
        isGain: true,
      ));
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
      await tester.pumpWidget(SettingsScope(
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
      ));
      unawaited(pushStarChangeScreen(
        context: navCtx,
        before: _rank(0),
        after: _rank(1),
        maxStarsEver: 1,
        isGain: true,
      ));
      await tester.pump(); // register route, build StarChangeScreen, initState runs
      // The route transition takes 300 ms. During this transition TickerMode
      // may be disabled for the new route's tickers.
      await tester.pump(const Duration(milliseconds: 300)); // route fully entered
      // Now _mainCtrl tickers are active. Advance past the 1500 ms animation
      // and the 200 ms close-timer.
      await tester.pump(const Duration(milliseconds: 1500)); // main anim completes
      await tester.pump(const Duration(milliseconds: 200));  // close timer fires
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
