import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bible_track/data/books_data.dart';
import 'package:bible_track/models/book.dart';
import 'package:bible_track/settings_scope.dart';
import 'package:bible_track/theme/app_theme.dart';
import 'package:bible_track/widgets/floating_pill_nav.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/library_fixture.dart';
import 'widget_test.dart' show FakeAuthService, FakeCloudRepository;

class _User implements User {
  @override
  String get uid => 'me';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth extends FakeAuthService {
  @override
  User get currentUser => _User();
}

class _Board extends FakeCloudRepository {
  final updates = StreamController<List<Map<String, dynamic>>>.broadcast();
  bool loading = false;
  List<Map<String, dynamic>> rows = List.generate(
    50,
    (i) => {
      'uid': 'reader-$i',
      'username': 'Reader ${i + 1}',
      'chaptersRead': 50 - i,
    },
  );
  @override
  Stream<List<Map<String, dynamic>>> leaderboardStream({
    int limit = 50,
  }) async* {
    if (!loading) yield rows;
    yield* updates.stream;
  }

  @override
  Future<int?> fetchOwnRank(String uid, int myChaptersRead) async => 51;
}

void main() {
  late LibraryFixture fixture;
  late _Board board;
  setUpAll(() async {
    await loadLibraryFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() async {
    board = _Board();
    fixture = LibraryFixture(cloud: board, auth: _Auth());
    await fixture.init();
  });
  tearDown(() async {
    await fixture.dispose();
    await board.updates.close();
  });
  final pill = find.byType(FloatingPillNav);
  final fab = find.byKey(const ValueKey('spin-fab'));
  Finder item(int i) => find.byKey(ValueKey('floating-nav-item-$i'));

  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'floating group animates as one row, with selected tab semantics',
    (tester) async {
      libraryPhone(tester, const Size(320, 640));
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        fixture.app(padding: const EdgeInsets.only(bottom: 24)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.getSize(pill).height, 68);
      expect(tester.getSize(pill).width, 200);
      expect(tester.getSize(fab), const Size(56, 56));
      expect(tester.getCenter(fab).dy, tester.getCenter(pill).dy);
      expect(tester.getRect(pill).bottom, 640 - 24 - 12);
      expect(tester.getRect(fab).left - tester.getRect(pill).right, 8);
      expect((tester.getRect(pill).left + tester.getRect(fab).right) / 2, 160);
      final booksCenter = tester.getCenter(pill).dx;
      for (var i = 0; i < 2; i++) {
        expect(tester.getSize(item(i)).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(item(i)).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(item(i)).width, 94);
        expect(
          tester.getSemantics(item(i)),
          matchesSemantics(
            label: fixture.settings.strings.navTabSemantics(
              i == 0
                  ? fixture.settings.strings.navBooks
                  : fixture.settings.strings.navLeaderboard,
              i + 1,
              2,
            ),
            isButton: true,
            hasSelectedState: true,
            isSelected: i == 0,
            hasTapAction: true,
            textDirection: TextDirection.ltr,
          ),
        );
      }
      final scheme = Theme.of(tester.element(pill)).colorScheme;
      final indicator = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('floating-nav-indicator-0')),
      );
      expect(
        (indicator.decoration! as BoxDecoration).color,
        scheme.primaryContainer,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('floating-nav-indicator-0'))),
        const Size(64, 32),
      );
      expect(
        tester
            .widget<Icon>(
              find.descendant(of: pill, matching: find.byType(Icon)).first,
            )
            .size,
        24,
      );
      final material = tester.widget<Material>(
        find.descendant(of: pill, matching: find.byType(Material)).first,
      );
      expect(material.color, scheme.surfaceContainerHigh);
      expect(material.color!.a, 1);
      expect(material.color, isNot(scheme.surface));
      expect(material.shape, isA<StadiumBorder>());
      expect((material.shape! as StadiumBorder).side.width, 1);
      expect(
        (material.shape! as StadiumBorder).side.color,
        scheme.outlineVariant,
      );
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: pill,
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as ShapeDecoration;
      expect(decoration.shadows!.single.blurRadius, 18);
      expect(decoration.shadows!.single.offset, const Offset(0, 5));
      final fabDecoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(of: fab, matching: find.byType(DecoratedBox))
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(fabDecoration.boxShadow, decoration.shadows);
      final label = find.descendant(of: pill, matching: find.text('Mga Libro'));
      expect(
        tester.getRect(pill).bottom - tester.getRect(label).bottom,
        greaterThanOrEqualTo(8),
      );
      await tester.tap(item(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getCenter(pill).dx, greaterThan(booksCenter));
      expect(tester.getCenter(pill).dx, lessThan(160));
      final opacity = find
          .ancestor(of: fab, matching: find.byType(Opacity))
          .first;
      expect(tester.widget<Opacity>(opacity).opacity, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(fab, findsNothing);
      expect(tester.getCenter(pill).dx, 160);
      expect(tester.widget<Semantics>(item(1)).properties.selected, isTrue);
      await tester.tap(item(0));
      await tester.pumpAndSettle();
      expect(fab.hitTestable(), findsOneWidget);
      expect(tester.getCenter(pill).dx, booksCenter);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'keyboard hides the floating controls and reduced motion settles immediately',
    (tester) async {
      libraryPhone(tester, const Size(320, 640));
      await tester.pumpWidget(fixture.app(reduceMotion: true));
      await tester.pumpAndSettle();
      await tester.tap(item(1));
      await tester.pump();
      expect(fab, findsNothing);
      expect(tester.getCenter(pill).dx, 160);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pump();
      expect(pill, findsNothing);
      expect(fab, findsNothing);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(pill, findsOneWidget);
      expect(tester.getCenter(pill).dx, 160);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final lang in ['fil', 'en']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$lang dark=$dark: 320 px at 1.6 scale clears all tab lists and anchors the hint',
        (tester) async {
          libraryPhone(tester, const Size(320, 640));
          fixture.settings.setLanguage(lang);
          final oldShadows = debugDisableShadows;
          if (const bool.fromEnvironment('CAPTURE_UI')) {
            debugDisableShadows = false;
            addTearDown(() => debugDisableShadows = oldShadows);
          }
          final captureKey = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: captureKey,
              child: fixture.app(
                dark: dark,
                scale: 1.6,
                padding: const EdgeInsets.only(bottom: 24),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await capture(tester, captureKey, 'pill-books-$lang-$dark');
          final hint = find.byKey(const ValueKey('spin-fab-hint'));
          expect(hint, findsOneWidget);
          expect(
            tester.getRect(hint).right,
            closeTo(tester.getRect(fab).right, .1),
          );
          expect(
            tester.getRect(fab).top - tester.getRect(hint).bottom,
            closeTo(8, .1),
          );
          expect(tester.getRect(hint).left, greaterThanOrEqualTo(16));
          expect(tester.getSize(pill).height, greaterThan(68));
          expect(tester.getSize(pill).width, 200);
          expect(
            tester.getCenter(fab).dy,
            closeTo(tester.getCenter(pill).dy, .01),
          );
          final navMaterial = tester.widget<Material>(
            find.descendant(of: pill, matching: find.byType(Material)).first,
          );
          final scheme = Theme.of(tester.element(pill)).colorScheme;
          expect(navMaterial.color, scheme.surfaceContainerHigh);
          expect(navMaterial.color!.a, 1);
          for (var i = 0; i < 2; i++) {
            final capsule = find.byKey(ValueKey('floating-nav-indicator-$i'));
            final label = find.descendant(
              of: item(i),
              matching: find.byType(Text),
            );
            expect(tester.getSize(capsule), const Size(64, 32));
            expect(
              tester.getRect(capsule).top - tester.getRect(pill).top,
              closeTo(8, .01),
            );
            expect(
              tester.getRect(label).top - tester.getRect(capsule).bottom,
              greaterThanOrEqualTo(4),
            );
            expect(
              tester.getRect(pill).bottom - tester.getRect(label).bottom,
              greaterThanOrEqualTo(8),
            );
          }
          await tester.tap(item(0));
          await tester.pumpAndSettle();
          await capture(tester, captureKey, 'pill-books-clear-$lang-$dark');
          final books = find.byType(CustomScrollView).first;
          final booksScroll = find.descendant(
            of: books,
            matching: find.byType(Scrollable),
          );
          for (final (group, id) in [
            (Section.oldTestament, 'mal'),
            (Section.newTestament, 'rev'),
            (Section.deuterocanonical, '2ma'),
          ]) {
            final chip = find.text(fixture.settings.strings.sectionName(group));
            await tester.ensureVisible(chip);
            await tester.pumpAndSettle();
            await tester.tap(chip);
            await tester.pumpAndSettle();
            final name = bookById(id).nameFor(lang);
            await tester.scrollUntilVisible(
              find.text(name),
              500,
              scrollable: booksScroll,
            );
            await tester.drag(books, const Offset(0, -1000));
            await tester.pumpAndSettle();
            final card = find
                .ancestor(of: find.text(name), matching: find.byType(Material))
                .first;
            expect(
              tester.getRect(card).bottom,
              lessThan(tester.getRect(pill).top),
            );
            expect(
              tester.getRect(card).bottom,
              lessThan(tester.getRect(fab).top),
            );
          }
          await tester.tap(item(1));
          await tester.pumpAndSettle();
          final list = find.byKey(const ValueKey('leaderboard-list'));
          final scrollable = find.descendant(
            of: list,
            matching: find.byType(Scrollable),
          );
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('leaderboard-reader-49')),
            500,
            scrollable: scrollable,
          );
          await tester.drag(list, const Offset(0, -1000));
          await tester.pumpAndSettle();
          expect(
            tester
                .getRect(find.byKey(const ValueKey('leaderboard-reader-49')))
                .bottom,
            lessThan(tester.getRect(pill).top),
          );
          expect(tester.getCenter(pill).dx, 160);
          expect(fab, findsNothing);
          expect(tester.takeException(), isNull);
          await capture(tester, captureKey, 'pill-ranggo-$lang-$dark');
          debugDisableShadows = oldShadows;
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets(
    'short leaderboard loading, empty and offline states clear the pill',
    (tester) async {
      libraryPhone(tester, const Size(320, 360));
      board.loading = true;
      await tester.pumpWidget(fixture.app(scale: 1.6));
      await tester.pump();
      await tester.tap(item(1));
      await tester.pump(const Duration(milliseconds: 220));
      await tester.pump();
      final status = find.byKey(const ValueKey('leaderboard-status'));
      final loading = find.byType(CircularProgressIndicator);
      expect(loading, findsOneWidget);
      expect(
        tester.getRect(loading).bottom,
        lessThan(tester.getRect(pill).top),
      );
      board.updates.add([]);
      await tester.pumpAndSettle();
      await tester.drag(status, const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(
        tester
            .getRect(find.text(fixture.settings.strings.leaderboardOptInPrompt))
            .bottom,
        lessThan(tester.getRect(pill).top),
      );
      board.updates.addError(StateError('offline'));
      await tester.pumpAndSettle();
      await tester.drag(status, const Offset(0, -1000));
      await tester.pumpAndSettle();
      final retry = find.text(fixture.settings.strings.leaderboardRetry);
      expect(retry.hitTestable(), findsOneWidget);
      expect(tester.getRect(retry).bottom, lessThan(tester.getRect(pill).top));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'three destinations support Tab, Enter, Space and icon-only labels',
    (tester) async {
      var selected = 0;
      final activated = <int>[];
      Future<void> mount(double scale, {bool many = false}) =>
          tester.pumpWidget(
            SettingsScope(
              controller: fixture.settings,
              child: MaterialApp(
                theme: lightTheme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: StatefulBuilder(
                    builder: (context, setState) => Center(
                      child: SizedBox(
                        width: many ? 200 : 280,
                        child: FloatingPillNav(
                          selectedIndex: selected,
                          onDestinationSelected: (i) {
                            activated.add(i);
                            setState(() => selected = i);
                          },
                          destinations: [
                            const FloatingPillDestination(
                              icon: Icons.menu_book,
                              label: 'Books',
                            ),
                            const FloatingPillDestination(
                              icon: Icons.emoji_events,
                              label: 'Leaderboard',
                            ),
                            const FloatingPillDestination(
                              icon: Icons.settings,
                              label: 'Settings',
                            ),
                            if (many) ...const [
                              FloatingPillDestination(
                                icon: Icons.search,
                                label: 'Search',
                              ),
                              FloatingPillDestination(
                                icon: Icons.person,
                                label: 'Profile',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
      await mount(1);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(activated, [0]);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(activated, [0, 1]);
      expect(tester.widget<Semantics>(item(1)).properties.selected, isTrue);
      await mount(3);
      await tester.pumpAndSettle();
      expect(find.text('Books'), findsNothing);
      expect(find.text('Leaderboard'), findsNothing);
      expect(find.text('Settings'), findsNothing);
      for (var i = 0; i < 3; i++) {
        expect(tester.getSize(item(i)).height, greaterThanOrEqualTo(48));
        expect(
          tester.widget<Semantics>(item(i)).properties.label,
          contains('tab ${i + 1}'),
        );
      }
      await mount(1, many: true);
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        expect(tester.getSize(item(i)).width, greaterThanOrEqualTo(48));
      }
      await tester.drag(
        find.descendant(of: pill, matching: find.byType(SingleChildScrollView)),
        const Offset(-1000, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(item(4));
      await tester.pumpAndSettle();
      expect(selected, 4);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
