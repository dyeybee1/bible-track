import 'package:bible_track/widgets/floating_pill_nav.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bible_track/data/account_controller.dart';
import 'package:bible_track/data/bible_text_repository.dart';
import 'package:bible_track/data/books_data.dart';
import 'package:bible_track/data/progress_controller.dart';
import 'package:bible_track/data/quiz_repository.dart';
import 'package:bible_track/data/rank_system.dart';
import 'package:bible_track/data/settings_controller.dart';
import 'package:bible_track/features/books/chapter_reader_screen.dart';
import 'package:bible_track/features/home/home_shell.dart';
import 'package:bible_track/features/profile/profile_screen.dart';
import 'package:bible_track/features/settings/settings_screen.dart';
import 'package:bible_track/features/rank/star_change_screen.dart';
import 'package:bible_track/settings_scope.dart';
import 'package:bible_track/theme/app_theme.dart';
import 'package:bible_track/widgets/profile_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'widget_test.dart' show FakeAuthService, FakeCloudRepository;

class _Quiz extends QuizRepository {
  @override
  Future<List<QuizQuestion>> questionsFor(String bookId, int chapter) async =>
      const [
        QuizQuestion(
          questionEn: 'Who rescued Lot?',
          questionFil: 'Sino ang nagligtas kay Lot?',
          optionsEn: ['Abram', 'Pharaoh', 'Lot'],
          optionsFil: ['Abram', 'Faraon', 'Lot'],
          answer: 0,
          explanationEn: 'Abram rescued Lot (Genesis 14).',
          explanationFil: 'Iniligtas ni Abram si Lot (Genesis 14).',
        ),
      ];
}

class _LoadedBible extends BibleTextRepository {
  _LoadedBible(this.verses);
  final List<Verse> verses;

  @override
  Future<List<Verse>> loadChapter(
    String bookId,
    int chapter,
    BibleTranslation translation,
  ) async => verses;
}

void main() {
  late ProgressController progress;
  late SettingsController settings;
  late AccountController account;
  late FakeCloudRepository cloud;
  final captureKey = GlobalKey();

  setUpAll(() async {
    // Actual bundled fonts also make optional local previews faithful to release.
    for (final entry in {
      'Newsreader': 'Newsreader',
      'PlusJakartaSans': 'PlusJakartaSans',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load('assets/fonts/${entry.value}.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() async {
    progress = ProgressController(
      await Hive.openBox('ui_p', bytes: Uint8List(0)),
    );
    settings =
        SettingsController(await Hive.openBox('ui_s', bytes: Uint8List(0)))
          ..setLanguage('fil')
          ..setUsername('Bryan');
    cloud = FakeCloudRepository();
    account = AccountController(
      auth: FakeAuthService(),
      cloud: cloud,
      progress: progress,
      settings: settings,
      box: await Hive.openBox('ui_a', bytes: Uint8List(0)),
    );
    progress.markUpTo(allBooks.first, 13);
  });
  tearDown(() async {
    account.dispose();
    progress.dispose();
    settings.dispose();
    await Hive.close();
  });

  Widget home() => HomeShell(
    progress: progress,
    account: account,
    cloud: cloud,
    quizRepo: _Quiz(),
  );
  Widget app(Widget page, {bool dark = false, double scale = 1}) =>
      SettingsScope(
        controller: settings,
        child: RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? darkTheme : lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: ProfileAccess(
                profileBuilder: (_) => ProfileScreen(progress: progress),
                settingsBuilder: (_) => SettingsScreen(account: account),
                child: child!,
              ),
            ),
            home: page,
          ),
        ),
      );

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('header-profile-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('header-settings-action')));
    await tester.pumpAndSettle();
  }

  void phone(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    await tester.pumpAndSettle();
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = await Directory(
        'build/serene_scripture',
      ).create(recursive: true);
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('two tabs keep their state when profile opens from any header', (
    tester,
  ) async {
    phone(tester, const Size(390, 844));
    await tester.pumpWidget(app(home()));
    await tester.pumpAndSettle();
    final navigation = find.byType(FloatingPillNav);
    expect(
      tester.widget<FloatingPillNav>(navigation).destinations,
      hasLength(2),
    );
    expect(
      find.descendant(of: navigation, matching: find.text('Profile')),
      findsNothing,
    );
    for (final tab in ['Mga Libro', 'Ranggo']) {
      await tester.tap(
        find.descendant(of: navigation, matching: find.text(tab)),
      );
      await tester.pumpAndSettle();
      final index = tester.widget<FloatingPillNav>(navigation).selectedIndex;
      await tester.tap(find.byKey(const ValueKey('header-profile-action')));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.widget<FloatingPillNav>(navigation).selectedIndex, index);
      expect(progress.chaptersReadTotal, 13);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final dark in [false, true]) {
    testWidgets(
      'narrow ${dark ? 'dark' : 'light'} library and settings support 200% text',
      (tester) async {
        phone(tester, const Size(320, 640));
        await tester.pumpWidget(app(home(), dark: dark, scale: 2));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await openSettings(tester);
        await tester.scrollUntilVisible(find.text('Mag-logout'), 300);
        expect(find.text('Mag-logout').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(progress.chaptersReadTotal, 13);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      '${dark ? 'dark' : 'light'} UI walkthrough and optional previews',
      (tester) async {
        phone(tester, const Size(390, 844));
        final mode = dark ? 'dark' : 'light';
        await tester.pumpWidget(app(home(), dark: dark));
        await tester.pumpAndSettle();
        await capture(tester, 'books-$mode');
        await tester.tap(find.byKey(const ValueKey('spin-fab')));
        await tester.pumpAndSettle();
        await capture(tester, 'spinner-$mode');
        await tester.pageBack();
        await tester.pumpAndSettle();
        await openSettings(tester);
        await capture(tester, 'settings-$mode');
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Genesis').first);
        await tester.pumpAndSettle();
        await capture(tester, 'chapters-$mode');
        await tester.tap(find.text('14'));
        await tester.pumpAndSettle();
        await capture(tester, 'chapter-sheet-$mode');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());

        final verses = (await tester.runAsync(
          () => BibleTextRepository().loadChapter(
            'gen',
            14,
            BibleTranslation.tl1905,
          ),
        ))!;
        final bible = _LoadedBible(verses);
        await tester.pumpWidget(
          app(
            ChapterReaderScreen(
              book: allBooks.first,
              chapter: 14,
              progress: progress,
              quizRepo: _Quiz(),
              bibleRepo: bible,
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        await capture(tester, 'reader-$mode');
        await tester.tap(find.byKey(const ValueKey('reader-quiz-action')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Faraon'));
        await tester.pumpAndSettle();
        await capture(tester, 'quiz-$mode');
        expect(
          find.byKey(const ValueKey('header-profile-action')),
          findsNothing,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('quiz-submit-action')),
              )
              .onPressed,
          isNotNull,
        );
        await tester.tap(find.byKey(const ValueKey('quiz-submit-action')));
        await tester.pumpAndSettle();
        await capture(tester, 'retry-$mode');
        await tester.tap(find.byKey(const ValueKey('quiz-retry-action')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Abram'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('quiz-submit-action')));
        await tester.pumpAndSettle();
        await capture(tester, 'passed-$mode');
        expect(progress.chaptersReadTotal, 13); // Presentation must never mark.
        await tester.pumpWidget(const SizedBox.shrink());

        await tester.pumpWidget(
          app(ProfileScreen(progress: progress), dark: dark),
        );
        await tester.pumpAndSettle();
        await capture(tester, 'profile-$mode');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          app(
            StarChangeScreen(
              before: rankForStars(13),
              after: rankForStars(14),
              maxStarsEver: 14,
              isGain: true,
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        await capture(tester, 'reward-$mode');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
