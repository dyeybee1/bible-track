import 'dart:async';
import 'dart:typed_data';

import 'package:bible_track/data/account_controller.dart';
import 'package:bible_track/data/auth_service.dart';
import 'package:bible_track/data/books_data.dart';
import 'package:bible_track/data/cloud_repository.dart';
import 'package:bible_track/data/progress_controller.dart';
import 'package:bible_track/data/public_profile.dart';
import 'package:bible_track/data/quiz_repository.dart';
import 'package:bible_track/data/settings_controller.dart';
import 'package:bible_track/features/books/chapter_screen.dart';
import 'package:bible_track/features/leaderboard/leaderboard_screen.dart';
import 'package:bible_track/features/profile/profile_screen.dart';
import 'package:bible_track/features/profile/profile_sections.dart';
import 'package:bible_track/features/profile/public_profile_screen.dart';
import 'package:bible_track/features/rank/rank_cards.dart';
import 'package:bible_track/settings_scope.dart';
import 'package:bible_track/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cloud implements CloudRepository {
  Future<PublicProfile?> Function(String) load = (_) async => null;
  final reads = <String>[];
  List<Map<String, dynamic>> rows = [];
  @override
  Future<PublicProfile?> fetchPublicProfile(String uid) {
    reads.add(uid);
    return load(uid);
  }

  @override
  Stream<List<Map<String, dynamic>>> leaderboardStream({int limit = 50}) =>
      Stream.value(rows);
  @override
  Future<int?> fetchOwnRank(String uid, int myChaptersRead) async => 1;
  @override
  Future<List<Map<String, dynamic>>?> fetchBookFinishers(
    String bookId, {
    int limit = 50,
  }) async => rows;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProgressController progress;
  late SettingsController settings;
  late AccountController account;
  late _Cloud cloud;

  setUp(() async {
    progress = ProgressController(await Hive.openBox('p', bytes: Uint8List(0)));
    settings = SettingsController(await Hive.openBox('s', bytes: Uint8List(0)));
    settings.setLanguage('en');
    settings.setUsername('My name');
    cloud = _Cloud();
    account = AccountController(
      auth: _Auth(),
      cloud: cloud,
      progress: progress,
      settings: settings,
      box: await Hive.openBox('a', bytes: Uint8List(0)),
    );
  });
  tearDown(() async {
    account.dispose();
    progress.dispose();
    settings.dispose();
    await Hive.close();
  });

  Widget app(Widget home) => SettingsScope(
    controller: settings,
    child: MaterialApp(theme: lightTheme, home: home),
  );
  PublicProfile profile() => PublicProfile(
    uid: 'other',
    username: 'Another reader',
    chaptersRead: totalChaptersInBible + 245,
    maxStars: totalChaptersInBible + 500,
    timesCompleted: 1,
    chaptersCycle: 245,
    completedBooks: 3,
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  testWidgets(
    'public profile loads once and uses the shared read-only details',
    (tester) async {
      final pending = Completer<PublicProfile?>();
      cloud.load = (_) => pending.future;
      await tester.pumpWidget(
        app(PublicProfileScreen(uid: 'other', cloud: cloud)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(profile());
      await tester.pumpAndSettle();
      expect(find.byType(ProfileDetails), findsOneWidget);
      expect(find.byType(ProfileStatsSection), findsOneWidget);
      expect(find.byType(CurrentRankCard), findsOneWidget);
      expect(find.byType(HighestRankCard), findsOneWidget);
      expect(find.text('Another reader'), findsOneWidget);
      expect(find.text('3/${allBooks.length}'), findsOneWidget);
      expect(find.text('245/$totalChaptersInBible'), findsOneWidget);
      expect(find.text('1 time'), findsOneWidget);
      final stats = find.byType(ProfileStatsSection);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.descendant(
                of: stats,
                matching: find.byType(LinearProgressIndicator),
              ),
            )
            .value,
        closeTo(245 / totalChaptersInBible, 0.00001),
      );
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Start over'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Last updated: 2 hours ago'),
        200,
      );
      expect(find.text('Last updated: 2 hours ago'), findsOneWidget);
      settings.setLanguage('fil');
      await tester.pumpAndSettle();
      expect(find.text('Huling update: 2 oras ang nakalipas'), findsOneWidget);
      expect(cloud.reads, ['other']);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('missing public doc shows unavailable in either language', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(PublicProfileScreen(uid: 'gone', cloud: cloud)),
    );
    await tester.pumpAndSettle();
    expect(find.text('This profile is not available.'), findsOneWidget);
    settings.setLanguage('fil');
    await tester.pump();
    expect(find.text('Hindi available ang profile na ito.'), findsOneWidget);
    expect(find.byType(ProfileDetails), findsNothing);
    expect(cloud.reads, ['gone']);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('offline profile shows retry and can load after reconnecting', (
    tester,
  ) async {
    cloud.load = (_) => Future.error(StateError('offline'));
    await tester.pumpWidget(
      app(PublicProfileScreen(uid: 'other', cloud: cloud)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not load this profile.'), findsOneWidget);
    cloud.load = (_) async => profile();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileDetails), findsOneWidget);
    expect(cloud.reads, ['other', 'other']);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'leaderboard own row opens local profile without a cloud profile read',
    (tester) async {
      cloud.rows = [
        {'uid': 'me', 'username': 'My name', 'chaptersRead': 0},
      ];
      await tester.pumpWidget(
        app(
          LeaderboardScreen(progress: progress, account: account, cloud: cloud),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('leaderboard-me')));
      await tester.pumpAndSettle();
      expect(find.text('View profile'), findsOneWidget);
      expect(find.text('Seed III'), findsNWidgets(2));
      await tester.tap(find.text('View profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byType(PublicProfileScreen), findsNothing);
      expect(cloud.reads, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('leaderboard other row opens the requested public document', (
    tester,
  ) async {
    cloud.rows = [
      {'uid': 'other', 'username': 'Another reader', 'chaptersRead': 245},
    ];
    cloud.load = (_) async => profile();
    await tester.pumpWidget(
      app(
        LeaderboardScreen(progress: progress, account: account, cloud: cloud),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('leaderboard-other')));
    await tester.pumpAndSettle();
    expect(find.text('Tree I'), findsNWidgets(2));
    await tester.tap(find.text('View profile'));
    await tester.pumpAndSettle();
    expect(find.byType(PublicProfileScreen), findsOneWidget);
    expect(cloud.reads, ['other']);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Finished by reader names reuse the profile preview', (
    tester,
  ) async {
    cloud.rows = [
      {'uid': 'other', 'username': 'Another reader', 'chaptersRead': 245},
    ];
    cloud.load = (_) async => profile();
    await tester.pumpWidget(
      app(
        ChapterScreen(
          book: allBooks.first,
          progress: progress,
          account: account,
          cloud: cloud,
          quizRepo: QuizRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 finished'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Another reader'));
    await tester.pumpAndSettle();
    expect(find.text('View profile'), findsOneWidget);
    expect(find.text('Tree I'), findsOneWidget);
    await tester.tap(find.text('View profile'));
    await tester.pumpAndSettle();
    expect(find.byType(PublicProfileScreen), findsOneWidget);
    expect(cloud.reads, ['other']);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
