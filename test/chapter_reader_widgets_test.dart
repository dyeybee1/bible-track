import 'dart:async';
import 'dart:typed_data';

import 'package:bible_track/data/account_controller.dart';
import 'package:bible_track/data/auth_service.dart';
import 'package:bible_track/data/bible_text_repository.dart';
import 'package:bible_track/data/books_data.dart';
import 'package:bible_track/data/cloud_repository.dart';
import 'package:bible_track/data/progress_controller.dart';
import 'package:bible_track/data/quiz_repository.dart';
import 'package:bible_track/data/settings_controller.dart';
import 'package:bible_track/features/books/chapter_reader_screen.dart';
import 'package:bible_track/features/books/chapter_screen.dart';
import 'package:bible_track/features/rank/star_change_screen.dart';
import 'package:bible_track/features/settings/settings_screen.dart';
import 'package:bible_track/features/settings/text_sources_screen.dart';
import 'package:bible_track/l10n/strings.dart';
import 'package:bible_track/settings_scope.dart';
import 'package:bible_track/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

class _Auth implements AuthService {
  @override
  User? get currentUser => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cloud implements CloudRepository {
  @override
  Future<List<Map<String, dynamic>>?> fetchBookFinishers(
    String bookId, {
    int limit = 50,
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Quiz extends QuizRepository {
  _Quiz({this.hasQuestions = true});
  final bool hasQuestions;
  @override
  Future<List<QuizQuestion>> questionsFor(String bookId, int chapter) async =>
      hasQuestions
      ? const [
          QuizQuestion(
            questionEn: 'Which answer?',
            questionFil: 'Aling sagot?',
            optionsEn: ['Correct', 'Wrong'],
            optionsFil: ['Tama', 'Mali'],
            answer: 0,
            explanationEn: 'Read the explanation before marking.',
            explanationFil: 'Basahin ang paliwanag bago markahan.',
          ),
        ]
      : const [];
}

class _Text extends BibleTextRepository {
  final requests = <(String, int, BibleTranslation)>[];
  Future<List<Verse>> Function(String, int, BibleTranslation)? respond;

  @override
  Future<List<Verse>> loadChapter(
    String bookId,
    int chapter,
    BibleTranslation translation,
  ) async {
    requests.add((bookId, chapter, translation));
    if (respond != null) return respond!(bookId, chapter, translation);
    if (bookId == 'est' &&
        (chapter == 5 || chapter == 15) &&
        translation == BibleTranslation.web) {
      throw BibleTextPendingException(bookId, chapter);
    }
    return [
      Verse(
        number: 1,
        text: translation == BibleTranslation.web
            ? 'In the beginning, God created the heavens and the earth.'
            : 'Nang pasimula ay nilikha ng Dios ang langit at ang lupa.',
      ),
    ];
  }
}

void main() {
  late ProgressController progress;
  late SettingsController settings;
  late AccountController account;
  late _Cloud cloud;
  late _Text bible;
  late _Quiz quiz;

  setUp(() async {
    progress = ProgressController(
      await Hive.openBox('reader_p', bytes: Uint8List(0)),
    );
    settings = SettingsController(
      await Hive.openBox('reader_s', bytes: Uint8List(0)),
    )..setLanguage('en');
    cloud = _Cloud();
    bible = _Text();
    quiz = _Quiz();
    account = AccountController(
      auth: _Auth(),
      cloud: cloud,
      progress: progress,
      settings: settings,
      box: await Hive.openBox('reader_a', bytes: Uint8List(0)),
    );
  });
  tearDown(() async {
    account.dispose();
    progress.dispose();
    settings.dispose();
    await Hive.close();
  });

  Widget app(Widget home, {bool dark = false, double scale = 1}) =>
      SettingsScope(
        controller: settings,
        child: MaterialApp(
          theme: dark ? darkTheme : lightTheme,
          home: home,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      );
  Widget chapters() => ChapterScreen(
    book: bookById('gen'),
    progress: progress,
    account: account,
    cloud: cloud,
    quizRepo: quiz,
    bibleRepo: bible,
  );
  Widget reader({String book = 'gen', int chapter = 1}) => ChapterReaderScreen(
    book: bookById(book),
    chapter: chapter,
    progress: progress,
    quizRepo: quiz,
    bibleRepo: bible,
  );
  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'unread chapter sheet offers reading and quiz count without marking',
    (tester) async {
      await tester.pumpWidget(app(chapters()));
      await tester.pumpAndSettle();
      await openSheet(tester);
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Take the quiz • 1 question'), findsOneWidget);
      expect(find.text('Mark all'), findsNothing);
      expect(find.text('Mark up to here'), findsNothing);
      expect(progress.chaptersReadLifetime, 0);
      await tester.tap(find.byKey(const ValueKey('chapter-read-action')));
      await tester.pumpAndSettle();
      expect(find.byType(ChapterReaderScreen), findsOneWidget);
      expect(progress.chaptersReadLifetime, 0);
      expect(find.byType(StarChangeScreen), findsNothing);
    },
  );

  testWidgets(
    'sheet quiz action starts the existing quiz without auto marking',
    (tester) async {
      await tester.pumpWidget(app(chapters()));
      await tester.pumpAndSettle();
      await openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('chapter-quiz-action')));
      await tester.pumpAndSettle();
      expect(find.text('Which answer?'), findsOneWidget);
      expect(progress.chaptersReadLifetime, 0);
    },
  );

  testWidgets(
    'read chapter offers Read again and keeps unmark confirmation and loss flow',
    (tester) async {
      progress.markChapterRead(bookById('gen'), 1);
      await tester.pumpWidget(app(chapters()));
      await tester.pumpAndSettle();
      await openSheet(tester);
      expect(find.text('Read again'), findsOneWidget);
      expect(find.text('Remove from read'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('chapter-unmark-action')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(progress.chaptersReadLifetime, 1);
      await openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('chapter-unmark-action')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, const Strings('en').unmarkConfirm),
      );
      await tester.pumpAndSettle();
      expect(progress.chaptersReadLifetime, 0);
      expect(progress.maxStarsEver, 1);
      expect(
        tester.widget<StarChangeScreen>(find.byType(StarChangeScreen)).isGain,
        isFalse,
      );
    },
  );

  testWidgets('no-question sheet keeps the explicit direct mark fallback', (
    tester,
  ) async {
    quiz = _Quiz(hasQuestions: false);
    await tester.pumpWidget(app(chapters()));
    await tester.pumpAndSettle();
    await openSheet(tester);
    expect(find.text('Mark as read'), findsOneWidget);
    expect(progress.chaptersReadLifetime, 0);
    await tester.tap(find.byKey(const ValueKey('chapter-quiz-action')));
    await tester.pumpAndSettle();
    expect(progress.chaptersReadLifetime, 1);
    expect(find.byType(StarChangeScreen), findsOneWidget);
  });

  testWidgets(
    'reader switches translation, changes font and navigates without progress changes',
    (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app(reader()));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('In the beginning', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('reader-translation-tl1905')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Nang pasimula', findRichText: true),
        findsOneWidget,
      );
      expect(settings.preferredBibleTranslation, BibleTranslation.tl1905);
      await tester.tap(find.byKey(const ValueKey('reader-font-larger')));
      await tester.pumpAndSettle();
      expect(settings.readerFontSize, 22);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('reader-verse-1')))
            .style
            ?.fontSize,
        22,
      );
      await tester.tap(find.byTooltip('Next chapter'));
      await tester.pumpAndSettle();
      expect(find.text('Genesis • Chapter 2'), findsOneWidget);
      expect(bible.requests.last.$2, 2);
      expect(progress.chaptersReadLifetime, 0);
      expect(progress.maxStarsEver, 0);
      expect(find.byType(StarChangeScreen), findsNothing);
    },
  );

  testWidgets(
    'reader quiz preserves explanations then explicit marking and star screen',
    (tester) async {
      await tester.pumpWidget(app(reader()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reader-quiz-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Correct'));
      await tester.pump();
      await tester.tap(find.text('Check answers'));
      await tester.pumpAndSettle();
      expect(find.text('Read the explanation before marking.'), findsOneWidget);
      expect(progress.chaptersReadLifetime, 0);
      await tester.tap(find.text('Mark as read'));
      await tester.pumpAndSettle();
      expect(progress.chaptersReadLifetime, 1);
      expect(find.byType(StarChangeScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.tapAt(const Offset(200, 400));
      await tester.pumpAndSettle();
      expect(find.text('You have already read this'), findsOneWidget);
    },
  );

  testWidgets(
    'already read reader has disabled action and never unmarks on opening',
    (tester) async {
      progress.markChapterRead(bookById('gen'), 1);
      await tester.pumpWidget(app(reader()));
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('reader-quiz-action')),
      );
      expect(button.onPressed, isNull);
      expect(find.text('You have already read this'), findsOneWidget);
      expect(progress.chaptersReadLifetime, 1);
      expect(find.byType(StarChangeScreen), findsNothing);
    },
  );

  for (final target in [
    ('tob', 1),
    ('est', 10),
    ('dan', 3),
    ('dan', 13),
    ('dan', 14),
  ]) {
    testWidgets(
      '${target.$1}/${target.$2}: Tagalog unavailable, whole English chapter and note',
      (tester) async {
        settings.setPreferredBibleTranslation(BibleTranslation.tl1905);
        await tester.pumpWidget(
          app(reader(book: target.$1, chapter: target.$2)),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(const Strings('en').readerEnglishOnly),
          findsOneWidget,
        );
        expect(
          tester
              .widget<ChoiceChip>(
                find.byKey(const ValueKey('reader-translation-tl1905')),
              )
              .onSelected,
          isNull,
        );
        expect(bible.requests.single.$3, BibleTranslation.web);
        expect(
          find.textContaining('Nang pasimula', findRichText: true),
          findsNothing,
        );
        expect(settings.preferredBibleTranslation, BibleTranslation.tl1905);
        expect(progress.chaptersReadLifetime, 0);
      },
    );
  }

  for (final lang in ['en', 'fil']) {
    testWidgets('$lang: pending text is friendly and quiz still works', (
      tester,
    ) async {
      settings.setLanguage(lang);
      await tester.pumpWidget(app(reader(book: 'est', chapter: 15)));
      await tester.pumpAndSettle();
      expect(find.text(Strings(lang).readerPending), findsOneWidget);
      expect(find.byKey(const ValueKey('reader-text-pending')), findsOneWidget);
      expect(find.byKey(const ValueKey('reader-text-error')), findsNothing);
      expect(progress.chaptersReadLifetime, 0);
      await tester.tap(find.byKey(const ValueKey('reader-quiz-action')));
      await tester.pumpAndSettle();
      expect(
        find.text(lang == 'fil' ? 'Aling sagot?' : 'Which answer?'),
        findsOneWidget,
      );
      expect(progress.chaptersReadLifetime, 0);
    });
  }

  testWidgets(
    'pending text with no questions still supports explicit mark action',
    (tester) async {
      quiz = _Quiz(hasQuestions: false);
      await tester.pumpWidget(app(reader(book: 'est', chapter: 15)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reader-text-pending')), findsOneWidget);
      expect(find.text('Mark as read'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('reader-quiz-action')));
      await tester.pumpAndSettle();
      expect(progress.chaptersRead('est'), contains(15));
      expect(find.byType(StarChangeScreen), findsOneWidget);
    },
  );

  testWidgets('loading, retryable errors and retry do not change progress', (
    tester,
  ) async {
    final pending = Completer<List<Verse>>();
    bible.respond = (_, _, _) => pending.future;
    await tester.pumpWidget(app(reader()));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(StateError('asset read failed'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-text-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-text-pending')), findsNothing);
    bible.respond = (_, _, _) async => const [
      Verse(number: 1, text: 'Recovered test text'),
    ];
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Recovered test text', findRichText: true),
      findsOneWidget,
    );
    expect(progress.chaptersReadLifetime, 0);
  });

  testWidgets('settings and reader credit both open localized attribution', (
    tester,
  ) async {
    await tester.pumpWidget(app(SettingsScreen(account: account)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Text sources'), 300);
    await tester.tap(find.text('Text sources'));
    await tester.pumpAndSettle();
    expect(find.byType(TextSourcesScreen), findsOneWidget);
    expect(find.textContaining('Public domain.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app(reader()));
    await tester.pumpAndSettle();
    await tester.tap(find.text(const Strings('en').readerCredit(true)));
    await tester.pumpAndSettle();
    expect(find.byType(TextSourcesScreen), findsOneWidget);
    settings.setLanguage('fil');
    await tester.pumpAndSettle();
    expect(find.text('Mga Pinagmulan ng Teksto'), findsOneWidget);
  });

  testWidgets('narrow dark reader and chapter sheet respect large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(chapters(), dark: true, scale: 1.6));
    await tester.pumpAndSettle();
    await openSheet(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('chapter-read-action')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('reader-quiz-action')), findsOneWidget);
  });
}
