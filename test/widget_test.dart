import 'dart:async';
import 'dart:io';

import 'package:bible_track/data/account_controller.dart';
import 'package:bible_track/data/auth_service.dart';
import 'package:bible_track/data/cloud_repository.dart';
import 'package:bible_track/data/progress_controller.dart';
import 'package:bible_track/data/settings_controller.dart';
import 'package:bible_track/data/sync_merge.dart';
import 'package:bible_track/features/auth/login_screen.dart';
import 'package:bible_track/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
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
  Future<SyncState> fetchState(String uid) async =>
      const SyncState(cycle: 0, books: {});

  @override
  Future<SyncState> sync(String uid, SyncState local) async => local;

  @override
  Future<void> updatePublicProfile({
    required String uid,
    required String username,
    required int chaptersRead,
    required int completedBooks,
  }) async {}

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

  testWidgets('app builds and shows the login screen when signed out', (
    tester,
  ) async {
    final progressBox = await Hive.openBox('progress');
    final settingsBox = await Hive.openBox('settings');
    final accountBox = await Hive.openBox('account');

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
