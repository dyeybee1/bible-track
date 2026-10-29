import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bible_track/data/account_controller.dart';
import 'package:bible_track/data/auth_service.dart';
import 'package:bible_track/data/books_data.dart';
import 'package:bible_track/data/cloud_repository.dart';
import 'package:bible_track/data/progress_controller.dart';
import 'package:bible_track/data/quiz_repository.dart';
import 'package:bible_track/data/settings_controller.dart';
import 'package:bible_track/data/sync_merge.dart';
import 'package:bible_track/features/books/quiz_screen.dart';
import 'package:bible_track/features/leaderboard/leaderboard_screen.dart';
import 'package:bible_track/features/profile/profile_screen.dart';
import 'package:bible_track/features/rank/rank_badge.dart';
import 'package:bible_track/settings_scope.dart';
import 'package:bible_track/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

class _QuizRepo extends QuizRepository {
  _QuizRepo({this.hasQuestions = false});
  final bool hasQuestions;

  @override
  Future<List<QuizQuestion>> questionsFor(String bookId, int chapter) async =>
      hasQuestions
      ? const [
          QuizQuestion(
            questionEn: 'Question?',
            questionFil: 'Tanong?',
            optionsEn: ['Correct', 'Wrong'],
            optionsFil: ['Tama', 'Mali'],
            answer: 0,
            explanationEn: 'Explanation',
            explanationFil: 'Paliwanag',
          ),
        ]
      : const [];
}

class _User implements User {
  @override
  String get uid => 'me';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements AuthService {
  @override
  User get currentUser => _User();
  @override
  Stream<User?> get authChanges => Stream.value(currentUser);
  @override
  Future<void> init() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cloud implements CloudRepository {
  final board = StreamController<List<Map<String, dynamic>>>.broadcast();
  SyncState? uploaded;
  int? publicChapters;
  int? rankChapters;

  @override
  Stream<List<Map<String, dynamic>>> leaderboardStream({int limit = 50}) =>
      board.stream;
  @override
  Future<int?> fetchOwnRank(String uid, int myChaptersRead) async {
    rankChapters = myChaptersRead;
    return 51;
  }

  @override
  Future<SyncState> sync(
    String uid,
    SyncState local, {
    bool showOnLeaderboard = false,
  }) async {
    uploaded = local;
    final merged = mergeStates(
      local,
      const SyncState(cycle: 0, books: {}, maxStarsEver: 5000),
    );
    publicChapters = showOnLeaderboard ? merged.chaptersReadLifetime : null;
    return merged;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory temp;
  late Box<dynamic> progressBox;
  late SettingsController settings;
  late ProgressController progress;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('rank_widgets_');
    Hive.init(temp.path);
    progressBox = await Hive.openBox<dynamic>('progress', bytes: Uint8List(0));
    progress = ProgressController(progressBox);
    settings = SettingsController(
      await Hive.openBox<dynamic>('settings', bytes: Uint8List(0)),
    );
    settings.setLanguage('en');
  });
  tearDown(() async {
    progress.dispose();
    settings.dispose();
    await progressBox.flush();
    await Hive.close();
    await temp.delete(recursive: true);
  });

  Widget app(Widget home, {bool dark = false}) => SettingsScope(
    controller: settings,
    child: MaterialApp(theme: dark ? darkTheme : lightTheme, home: home),
  );

  Widget quizHost(QuizRepository repo, {int chapter = 10}) => app(
    Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showQuiz(
            context: context,
            book: allBooks.first,
            chapter: chapter,
            quizRepo: repo,
            progress: progress,
            lang: 'en',
          ),
          child: const Text('Open quiz'),
        ),
      ),
    ),
  );

  testWidgets(
    'profile always shows both ranks and quietly updates after sync and unmark',
    (tester) async {
      progress.markUpTo(allBooks.first, 10);
      await tester.pumpWidget(app(ProfileScreen(progress: progress)));
      expect(find.text('Current Rank'), findsOneWidget);
      expect(find.text('Highest Rank'), findsOneWidget);
      expect(find.text('Seed II'), findsNWidgets(2));
      expect(find.byType(RankBadge), findsNWidgets(2));
      expect(find.byType(AlertDialog), findsNothing);
      progress.toggleChapter(allBooks.first, 10);
      await tester.pump();
      expect(find.text('Seed III'), findsOneWidget);
      expect(find.text('Seed II'), findsOneWidget);
      expect(find.text('9 / 10 stars'), findsOneWidget);
      progress.applyMerge(
        0,
        {},
        progress.exportRecords(),
        mergedMaxStarsEver: 75,
      );
      await tester.pump();
      expect(find.text('Plant III'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      settings.setLanguage('fil');
      await tester.pump();
      expect(find.text('Pinakamataas na Rank'), findsOneWidget);
      expect(find.text('Binhi III'), findsOneWidget);
      expect(find.text('Halaman III'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('top rank shows total lifetime stars on a narrow dark profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    progress.applyMerge(1, {
      'gen': BookRecord({1}, 1),
    }, {});
    await tester.pumpWidget(app(ProfileScreen(progress: progress), dark: true));
    expect(find.text('${totalChaptersInBible + 1} stars'), findsOneWidget);
    expect(find.text('Word of Life'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('no-quiz direct mark celebrates a division once', (tester) async {
    progress.markUpTo(allBooks.first, 9);
    await tester.pumpWidget(quizHost(_QuizRepo()));
    await tester.tap(find.text('Open quiz'));
    await tester.pumpAndSettle();
    expect(progress.chaptersReadLifetime, 10);
    expect(find.text('New rank!'), findsOneWidget);
    expect(find.text('Seed II'), findsOneWidget);
    await tester.tap(find.text('Lovely!'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open quiz'));
    await tester.pumpAndSettle();
    expect(progress.chaptersReadLifetime, 10);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('no-quiz tier promotion celebrates the new tier', (tester) async {
    progress.markUpTo(allBooks.first, 29);
    await tester.pumpWidget(quizHost(_QuizRepo(), chapter: 30));
    await tester.tap(find.text('Open quiz'));
    await tester.pumpAndSettle();
    expect(progress.chaptersReadLifetime, 30);
    expect(find.text('Sprout III'), findsOneWidget);
    await tester.tap(find.text('Lovely!'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ordinary and unlimited top-tier chapter gains stay quiet', (
    tester,
  ) async {
    await tester.pumpWidget(quizHost(_QuizRepo()));
    await tester.tap(find.text('Open quiz'));
    await tester.pumpAndSettle();
    expect(progress.chaptersReadLifetime, 1);
    expect(find.byType(AlertDialog), findsNothing);
    progress.applyMerge(1, {}, progress.exportRecords());
    await tester.tap(find.text('Open quiz'));
    await tester.pumpAndSettle();
    expect(progress.chaptersReadLifetime, totalChaptersInBible + 1);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('passing a quiz celebrates only after Mark as read', (
    tester,
  ) async {
    progress.markUpTo(allBooks.first, 9);
    await tester.pumpWidget(quizHost(_QuizRepo(hasQuestions: true)));
    await tester.tap(find.text('Open quiz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Correct'));
    await tester.pump();
    await tester.tap(find.text('Check answers'));
    await tester.pumpAndSettle();
    expect(progress.chaptersReadLifetime, 9);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Mark as read'));
    await tester.pumpAndSettle();
    expect(progress.chaptersReadLifetime, 10);
    expect(find.text('New rank!'), findsOneWidget);
    await tester.tap(find.text('Lovely!'));
    await tester.pumpAndSettle();
    expect(find.text('Open quiz'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('sync during quiz and failed answers do not celebrate', (
    tester,
  ) async {
    progress.markUpTo(allBooks.first, 9);
    await tester.pumpWidget(quizHost(_QuizRepo(hasQuestions: true)));
    await tester.tap(find.text('Open quiz'));
    await tester.pumpAndSettle();
    progress.applyMerge(0, {
      'gen': BookRecord({for (var c = 1; c <= 10; c++) c}, 9999999999999),
    }, progress.exportRecords());
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Wrong'));
    await tester.pump();
    await tester.tap(find.text('Check answers'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(progress.chaptersReadLifetime, 10);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Correct'));
    await tester.pump();
    await tester.tap(find.text('Check answers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as read'));
    await tester.pumpAndSettle();
    expect(progress.chaptersReadLifetime, 10);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'leaderboard derives current ranks from public counts and keeps own row',
    (tester) async {
      final cloud = _Cloud();
      final accountBox = (await tester.runAsync(
        () => Hive.openBox<dynamic>('account', bytes: Uint8List(0)),
      ))!;
      final account = AccountController(
        auth: _Auth(),
        cloud: cloud,
        progress: progress,
        settings: settings,
        box: accountBox,
      );
      progress.applyMerge(1, {}, {}, mergedMaxStarsEver: 5000);
      settings.setUsername('My name');
      await tester.pumpWidget(
        app(
          LeaderboardScreen(progress: progress, account: account, cloud: cloud),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      cloud.board.add([
        {'uid': 'other', 'username': 'Reader', 'chaptersRead': 245},
        {'uid': 'me', 'username': 'My name', 'chaptersRead': 29},
      ]);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Tree I'), findsOneWidget);
      expect(find.text('Seed I'), findsOneWidget);
      expect(find.text('245 chapters'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Highest Rank'), findsNothing);
      expect(cloud.rankChapters, totalChaptersInBible);
      cloud.board.add([
        {'uid': 'other', 'username': 'Reader', 'chaptersRead': 245},
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Your rank: #51'), findsOneWidget);
      expect(find.text('Word of Life'), findsOneWidget);
      expect(find.text('$totalChaptersInBible chapters'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      account.dispose();
      await cloud.board.close();
    },
  );

  testWidgets(
    'account sync uploads private peak and publishes lifetime chapters',
    (tester) async {
      final cloud = _Cloud();
      settings.setUsername('My name');
      settings.setShowOnLeaderboard(true);
      progress.applyMerge(1, {}, {}, mergedMaxStarsEver: 3000);
      final account = AccountController(
        auth: _Auth(),
        cloud: cloud,
        progress: progress,
        settings: settings,
        box: (await tester.runAsync(
          () => Hive.openBox<dynamic>('account', bytes: Uint8List(0)),
        ))!,
      );
      await tester.runAsync(() async {
        await account.start();
        await Future<void>.delayed(Duration.zero);
        await account.syncNow();
        await Future<void>.delayed(Duration.zero);
      });
      expect(cloud.uploaded?.maxStarsEver, 3000);
      expect(progress.maxStarsEver, 5000);
      expect(cloud.publicChapters, totalChaptersInBible);
      expect(cloud.uploaded?.toMap().containsKey('rank'), isFalse);
      expect(cloud.uploaded?.toMap().containsKey('stars'), isFalse);
      account.dispose();
      await cloud.board.close();
    },
  );
}
