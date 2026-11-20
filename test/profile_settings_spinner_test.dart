import 'package:bible_track/widgets/floating_pill_nav.dart';
import 'package:bible_track/data/books_data.dart';
import 'package:bible_track/features/profile/profile_screen.dart';
import 'package:bible_track/features/settings/settings_screen.dart';
import 'package:bible_track/features/settings/text_sources_screen.dart';
import 'package:bible_track/widgets/scripture_quote.dart';
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

  final avatar = find.byKey(const ValueKey('header-profile-action'));
  final settingsAction = find.byKey(const ValueKey('header-settings-action'));
  Finder wheel() => find.byWidgetPredicate(
    (widget) =>
        widget is CustomPaint &&
        widget.painter.runtimeType.toString() == '_WheelPainter',
  );

  for (final language in ['fil', 'en']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$language root headers retain Profile at 320 px, dark=$dark',
        (tester) async {
          libraryPhone(tester, const Size(320, 740));
          fixture.settings.setLanguage(language);
          await tester.pumpWidget(fixture.app(dark: dark, scale: 1.6));
          await tester.pumpAndSettle();
          void checkAvatar() {
            expect(avatar.hitTestable(), findsOneWidget);
            final header = find.byType(AppBar).hitTestable();
            expect(tester.getRect(avatar).right, lessThanOrEqualTo(312));
            expect(
              tester.getRect(avatar).top,
              greaterThanOrEqualTo(tester.getRect(header).top),
            );
            expect(tester.takeException(), isNull);
          }

          checkAvatar();
          final nav = find.byType(FloatingPillNav);
          await tester.tap(
            find.descendant(
              of: nav,
              matching: find.text(fixture.settings.strings.navLeaderboard),
            ),
          );
          await tester.pumpAndSettle();
          checkAvatar();
          await tester.tap(
            find.descendant(
              of: nav,
              matching: find.text(fixture.settings.strings.navBooks),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('spin-fab')));
          await tester.pumpAndSettle();
          checkAvatar();
          await tester.tap(avatar);
          await tester.pumpAndSettle();
          expect(find.byType(ProfileScreen), findsOneWidget);
          expect(settingsAction.hitTestable(), findsOneWidget);
          expect(
            find.descendant(
              of: settingsAction,
              matching: find.byIcon(Icons.settings_outlined),
            ),
            findsOneWidget,
          );
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  for (final lang in ['fil', 'en']) {
    for (final size in [
      const Size(360, 740),
      const Size(320, 740),
      const Size(320, 640),
    ]) {
      testWidgets('$lang $size: spinner controls fit without scrolling', (
        tester,
      ) async {
        libraryPhone(tester, size);
        fixture.settings.setLanguage(lang);
        fixture.progress.markAll(allBooks.first);
        await tester.pumpWidget(
          fixture.app(
            spinner: true,
            padding: const EdgeInsets.only(top: 24, bottom: 24),
          ),
        );
        await tester.pumpAndSettle();
        final strings = fixture.settings.strings;
        final heading = lang == 'fil'
            ? 'Nag-iisip kung ano ang babasahin?'
            : 'Wondering what to read?';
        final title = lang == 'fil' ? 'Paikot' : 'Spin';
        expect(find.text(heading), findsOneWidget);
        expect(
          find.descendant(of: find.byType(AppBar), matching: find.text(title)),
          findsOneWidget,
        );
        expect(find.text('Ano ang babasahin?'), findsNothing);
        expect(find.text('What to read?'), findsNothing);
        expect(
          find.text('Hindi alam kung ano ang babasahin? Paikutin ang gulong.'),
          findsNothing,
        );
        expect(
          find.text('Not sure what to read? Spin the wheel.'),
          findsNothing,
        );
        expect(find.byType(ScriptureQuote), findsNothing);
        expect(find.text(strings.guidingVerseReference), findsNothing);
        expect(find.textContaining(strings.guidingVerse), findsNothing);
        expect(avatar, findsOneWidget);
        final scroll = tester
            .state<ScrollableState>(find.byType(Scrollable).last)
            .position;
        expect(scroll.maxScrollExtent, closeTo(0, 0.01));
        for (final control in [
          wheel(),
          find.text(strings.wheelCount(72)),
          find.byType(SwitchListTile),
          find.byType(FilledButton),
        ]) {
          expect(control.hitTestable(), findsOneWidget);
          final rect = tester.getRect(control);
          expect(
            rect.top,
            greaterThanOrEqualTo(tester.getRect(find.byType(AppBar)).bottom),
          );
          expect(rect.bottom, lessThanOrEqualTo(size.height - 24));
        }
        expect(tester.getSize(wheel()).width, inInclusiveRange(160, 340));
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(find.text(strings.wheelCount(73)), findsOneWidget);
        expect(scroll.maxScrollExtent, closeTo(0, 0.01));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    for (final dark in [false, true]) {
      testWidgets(
        '$lang dark=$dark: large spinner text scrolls without overflow',
        (tester) async {
          libraryPhone(tester, const Size(320, 640));
          fixture.settings.setLanguage(lang);
          await tester.pumpWidget(
            fixture.app(
              spinner: true,
              scale: 1.6,
              dark: dark,
              padding: const EdgeInsets.only(top: 24, bottom: 24),
            ),
          );
          await tester.pumpAndSettle();
          expect(avatar, findsOneWidget);
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -500),
          );
          await tester.pumpAndSettle();
          expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );

      testWidgets(
        '$lang dark=$dark: Profile gear pushes Settings and preserves links and back',
        (tester) async {
          libraryPhone(tester, const Size(320, 640));
          fixture.settings.setLanguage(lang);
          await tester.pumpWidget(fixture.app(scale: 1.6, dark: dark));
          await tester.pumpAndSettle();
          final nav = find.byType(FloatingPillNav);
          expect(
            tester.widget<FloatingPillNav>(nav).destinations,
            hasLength(2),
          );
          expect(
            find.descendant(
              of: nav,
              matching: find.text(fixture.settings.strings.navSettings),
            ),
            findsNothing,
          );
          final avatarSize = tester.getSize(avatar);
          await tester.tap(avatar);
          await tester.pumpAndSettle();
          expect(find.byType(ProfileScreen), findsOneWidget);
          expect(avatar, findsNothing);
          expect(find.byType(BackButton), findsOneWidget);
          expect(
            find.byTooltip(fixture.settings.strings.navSettings),
            findsOneWidget,
          );
          expect(tester.getSize(settingsAction), avatarSize);
          expect(
            tester.getSize(settingsAction).width,
            greaterThanOrEqualTo(48),
          );
          expect(
            find.descendant(
              of: settingsAction,
              matching: find.byIcon(Icons.settings_outlined),
            ),
            findsOneWidget,
          );
          final semantics = tester.ensureSemantics();
          expect(
            find.bySemanticsLabel(fixture.settings.strings.navSettings),
            findsWidgets,
          );
          semantics.dispose();
          await tester.tap(settingsAction);
          await tester.pumpAndSettle();
          expect(find.byType(SettingsScreen), findsOneWidget);
          expect(find.byType(BackButton), findsOneWidget);
          expect(avatar, findsNothing);
          for (final icon in [
            Icons.dark_mode_outlined,
            Icons.light_mode_outlined,
          ]) {
            expect(
              find.descendant(
                of: find.byType(AppBar),
                matching: find.byIcon(icon),
              ),
              findsNothing,
            );
          }
          expect(settingsAction, findsNothing);
          await tester.scrollUntilVisible(
            find.textContaining(
              fixture.settings.strings.publicProfilePrivacyNotice,
            ),
            200,
          );
          expect(
            find.textContaining(
              fixture.settings.strings.publicProfilePrivacyNotice,
            ),
            findsOneWidget,
          );
          await tester.scrollUntilVisible(
            find.text(fixture.settings.strings.textSources).hitTestable(),
            250,
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.text(fixture.settings.strings.textSources),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(fixture.settings.strings.textSources));
          await tester.pumpAndSettle();
          expect(find.byType(TextSourcesScreen), findsOneWidget);
          expect(avatar, findsOneWidget);
          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(find.byType(SettingsScreen), findsOneWidget);
          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(find.byType(ProfileScreen), findsOneWidget);
          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('spin-fab')), findsOneWidget);
          expect(tester.widget<FloatingPillNav>(nav).selectedIndex, 0);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
