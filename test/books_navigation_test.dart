import 'package:bible_track/data/settings_controller.dart';
import 'package:bible_track/features/books/chapter_screen.dart';
import 'package:bible_track/features/spinner/spinner_screen.dart';
import 'package:bible_track/widgets/page_heading.dart';
import 'package:bible_track/widgets/spin_wheel_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/library_fixture.dart';

void main() {
  late LibraryFixture fixture;
  setUpAll(loadLibraryFonts);
  setUp(() async {
    fixture = LibraryFixture();
    await fixture.init();
  });
  tearDown(() => fixture.dispose());

  final fab = find.byKey(const ValueKey('spin-fab'));
  final hint = find.byKey(const ValueKey('spin-fab-hint'));
  final chips = find.byKey(const ValueKey('testament-chips'));
  Finder nav(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  testWidgets(
    'compact books have pinned chips, visible Genesis and safe last card',
    (tester) async {
      libraryPhone(tester);
      await tester.pumpWidget(
        fixture.app(padding: const EdgeInsets.only(bottom: 24)),
      );
      await tester.pumpAndSettle();
      expect(find.text('PANG-ARAW-ARAW NA GABAY'), findsNothing);
      expect(find.text('Magbasa nang may kapayapaan'), findsNothing);
      expect(
        find.text('Talaan ng iyong pagbabasa at paglalakbay'),
        findsNothing,
      );
      expect(find.byType(PageHeading), findsNothing);
      expect(find.text('0/39 natapos'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Mga Libro'), findsOneWidget); // Navigation only.
      expect(find.text('Genesis').hitTestable(), findsOneWidget);
      expect(
        tester.getRect(chips).top - tester.getRect(find.byType(AppBar)).bottom,
        inInclusiveRange(8, 12),
      );
      final position = tester.getRect(chips);
      final list = find.byType(CustomScrollView).first;
      await tester.scrollUntilVisible(
        find.text('Malakias'),
        600,
        scrollable: find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.drag(list, const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(tester.getRect(chips), position);
      final lastCard = tester.getRect(
        find
            .ancestor(
              of: find.text('Malakias'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(lastCard.bottom, lessThanOrEqualTo(tester.getRect(fab).top));
      expect(tester.getRect(fab).size, const Size(56, 56));
      expect(
        tester.getRect(find.byType(NavigationBar)).top -
            tester.getRect(fab).bottom,
        16,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('three tabs preserve section and FAB opens a backable spinner', (
    tester,
  ) async {
    libraryPhone(tester);
    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
      hasLength(3),
    );
    expect(nav('Paikot'), findsNothing);
    expect(find.byType(SpinWheelIcon), findsOneWidget);
    expect(
      find.byTooltip(fixture.settings.strings.spinReadingHint),
      findsOneWidget,
    );
    final semantics = tester.ensureSemantics();
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(fixture.settings.strings.spinReadingHint).last,
      ),
      matchesSemantics(
        label: fixture.settings.strings.spinReadingHint,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
    await tester.tap(find.text('Bagong Tipan'));
    await tester.pumpAndSettle();
    for (final label in ['Ranggo', 'Setting']) {
      await tester.tap(nav(label));
      await tester.pumpAndSettle();
      expect(fab, findsNothing);
    }
    await tester.tap(nav('Mga Libro'));
    await tester.pumpAndSettle();
    expect(find.text('Mateo').hitTestable(), findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();
    expect(find.byType(SpinnerScreen), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(fab, findsOneWidget);
    expect(find.text('Mateo').hitTestable(), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'hint dismisses on any tap and stays seen after settings reload',
    (tester) async {
      libraryPhone(tester);
      await tester.pumpWidget(fixture.app(reduceMotion: true));
      await tester.pumpAndSettle();
      expect(hint, findsOneWidget);
      expect(fixture.settings.spinHintSeen, isTrue);
      await tester.tapAt(const Offset(5, 150));
      await tester.pumpAndSettle();
      expect(hint, findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      final restored = SettingsController(fixture.settingsBox);
      expect(restored.spinHintSeen, isTrue);
      restored.dispose();
      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();
      expect(hint, findsNothing);
      await tester.tap(nav('Setting'));
      await tester.pumpAndSettle();
      await tester.tap(nav('Mga Libro'));
      await tester.pumpAndSettle();
      expect(hint, findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('hint times out after six seconds without interaction', (
    tester,
  ) async {
    libraryPhone(tester);
    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();
    expect(hint, findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(hint, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final lang in ['fil', 'en']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$lang dark=$dark: 320px and 200% text keep chips, hint and FAB usable',
        (tester) async {
          libraryPhone(tester, const Size(320, 640));
          fixture.settings.setLanguage(lang);
          await tester.pumpWidget(fixture.app(dark: dark, scale: 2));
          await tester.pumpAndSettle();
          expect(hint, findsOneWidget);
          expect(find.text('Genesis').hitTestable(), findsOneWidget);
          expect(
            tester.getRect(fab).bottom,
            lessThan(tester.getRect(find.byType(NavigationBar)).top),
          );
          await tester.drag(chips, const Offset(-1000, 0));
          await tester.pumpAndSettle();
          expect(find.text('Deuterocanonical').hitTestable(), findsOneWidget);
          await tester.tap(find.text('Deuterocanonical'));
          await tester.pumpAndSettle();
          expect(find.text('Tobit').hitTestable(), findsOneWidget);
          await tester.tap(fab);
          await tester.pumpAndSettle();
          expect(find.byType(BackButton), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets(
    'pushed spinner keeps scope, repeat, result and chapter routes working',
    (tester) async {
      libraryPhone(tester);
      await tester.pumpWidget(fixture.app(reduceMotion: true));
      await tester.pumpAndSettle();
      await tester.tap(fab);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byTooltip(fixture.settings.strings.spinScopeSemantics),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bagong Tipan'));
      await tester.pumpAndSettle();
      expect(find.text('27 libro sa gulong.'), findsOneWidget);
      await tester.ensureVisible(find.text('Paikutin'));
      await tester.tap(find.text('Paikutin'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tap(find.text('Ikot ulit'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tap(find.text('Buksan ang libro'));
      await tester.pumpAndSettle();
      expect(find.byType(ChapterScreen), findsOneWidget);
      expect(fixture.progress.chaptersReadTotal, 0);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SpinnerScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(fab, findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
