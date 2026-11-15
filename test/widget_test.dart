import 'package:bible_track/data/public_profile.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bible_track/data/account_controller.dart';
import 'package:bible_track/data/auth_service.dart';
import 'package:bible_track/data/cloud_repository.dart';
import 'package:bible_track/data/progress_controller.dart';
import 'package:bible_track/data/quiz_repository.dart';
import 'package:bible_track/data/settings_controller.dart';
import 'package:bible_track/data/sync_merge.dart';
import 'package:bible_track/features/auth/login_screen.dart';
import 'package:bible_track/main.dart';
import 'package:bible_track/settings_scope.dart';
import 'package:bible_track/theme/app_theme.dart';
import 'package:bible_track/widgets/app_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

/// Stand-in for AuthService: nobody is logged in, and Firebase is never touched.
class FakeAuthService implements AuthService {
  @override
  Future<void> init() async {}

  @override
  Stream<User?> get authChanges => Stream<User?>.value(null);

  @override
  User? get currentUser => null;

  @override
  Future<SignInResult> signInWithGoogle() async => SignInResult.cancelled;

  @override
  Future<SignInResult> switchAccount() async => SignInResult.cancelled;

  @override
  Future<void> signOut() async {}
}

/// Stand-in for CloudRepository: nothing is read from or written to Firestore.
class FakeCloudRepository implements CloudRepository {
  @override
  Future<PublicProfile?> fetchPublicProfile(String uid) async => null;

  @override
  Future<SyncState> fetchState(String uid) async =>
      const SyncState(cycle: 0, books: {});

  @override
  Future<SyncState> sync(
    String uid,
    SyncState local, {
    bool showOnLeaderboard = false,
  }) async => local;

  @override
  Future<void> deletePublicProfile(String uid) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchLeaderboard({int limit = 50}) async =>
      [];

  @override
  Stream<List<Map<String, dynamic>>> leaderboardStream({int limit = 50}) =>
      Stream.value([]);

  @override
  Future<int?> fetchOwnRank(String uid, int myChaptersRead) async => null;

  @override
  Future<List<Map<String, dynamic>>?> fetchBookFinishers(
    String bookId, {
    int limit = 50,
  }) async => [];
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bible_track_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('header theme toggle updates and saves the app appearance', (
    tester,
  ) async {
    final box = await Hive.openBox('header_settings', bytes: Uint8List(0));
    final settings = SettingsController(box);
    await tester.pumpWidget(
      SettingsScope(
        controller: settings,
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => MaterialApp(
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: settings.themeMode,
            home: Builder(
              builder: (context) => Scaffold(
                appBar: appHeader(context, title: 'Books', themeToggle: true),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Books'), findsOneWidget);
    await tester.tap(find.byTooltip(settings.strings.themeDark));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Books'))).brightness,
      Brightness.dark,
    );
    final restored = SettingsController(box);
    expect(restored.themeMode, ThemeMode.dark);
    restored.dispose();
    await tester.tap(find.byTooltip(settings.strings.themeLight));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Books'))).brightness,
      Brightness.light,
    );
    expect(box.get('theme'), 'light');
    await tester.pumpWidget(const SizedBox.shrink());
    settings.dispose();
  });

  testWidgets('app builds and shows the login screen when signed out', (
    tester,
  ) async {
    // Keep widget tests independent of file I/O under the fake clock.
    final progressBox = await Hive.openBox('progress', bytes: Uint8List(0));
    final settingsBox = await Hive.openBox('settings', bytes: Uint8List(0));
    final accountBox = await Hive.openBox('account', bytes: Uint8List(0));

    final progress = ProgressController(progressBox);
    final settings = SettingsController(settingsBox);
    final cloud = FakeCloudRepository();
    final account = AccountController(
      auth: FakeAuthService(),
      cloud: cloud,
      progress: progress,
      settings: settings,
      box: accountBox,
    );
    await account.start();

    await tester.pumpWidget(
      BibleTrackApp(
        progress: progress,
        settings: settings,
        account: account,
        cloud: cloud,
        quizRepo: QuizRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BibleTrackApp), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);

    // Remove the app first, then dispose the controller.
    await tester.pumpWidget(const SizedBox.shrink());
    account.dispose();
  });
}
