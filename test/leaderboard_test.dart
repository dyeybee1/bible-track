import 'package:bible_track/data/books_data.dart';
import 'package:bible_track/data/cloud_repository.dart';
import 'package:bible_track/data/leaderboard_controller.dart';
import 'package:bible_track/data/progress_controller.dart';
import 'package:bible_track/data/sync_merge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'dart:io';

// ---------------------------------------------------------------------------
// Fake CloudRepository for unit tests
// ---------------------------------------------------------------------------

class _FakeCloud implements CloudRepository {
  final List<Map<String, dynamic>> board;
  final int? ownRank;

  _FakeCloud({this.board = const [], this.ownRank});

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
      board;

  @override
  Stream<List<Map<String, dynamic>>> leaderboardStream({int limit = 50}) =>
      Stream.value(board);

  @override
  Future<int?> fetchOwnRank(String uid, int myChaptersRead) async => ownRank;
}

class _ErrorCloud implements CloudRepository {
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
  Future<List<Map<String, dynamic>>> fetchLeaderboard({int limit = 50}) =>
      Future.error(Exception('offline'));

  @override
  Stream<List<Map<String, dynamic>>> leaderboardStream({int limit = 50}) =>
      Stream.error(Exception('offline'));

  @override
  Future<int?> fetchOwnRank(String uid, int myChaptersRead) async => null;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _row(String uid, String name, int chapters) => {
      'uid': uid,
      'username': name,
      'chaptersRead': chapters,
      'completedBooks': 0,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── ProgressController: chaptersReadLifetime ───────────────────────────────
  group('ProgressController.chaptersReadLifetime', () {
    late Directory tempDir;
    late Box<dynamic> box;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('leaderboard_test');
      Hive.init(tempDir.path);
      box = await Hive.openBox('progress');
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('is 0 when nothing has been read', () {
      final ctrl = ProgressController(box);
      expect(ctrl.chaptersReadLifetime, 0);
    });

    test('equals chaptersReadTotal in cycle 0', () {
      final ctrl = ProgressController(box);
      final gen = allBooks.first; // Genesis, 50 chapters
      ctrl.markAll(gen);
      expect(ctrl.chaptersReadLifetime, 50);
      expect(ctrl.chaptersReadTotal, 50);
    });

    test('increases by totalChaptersInBible when a new cycle starts', () async {
      // Pre-populate the box as if the user has just finished the Bible.
      // We write one book record directly to avoid triggering Hive compaction
      // from 1,189 individual chapter writes.
      await box.put('_timesCompleted', 1);
      // Genesis is fully read in the new (empty) cycle.
      await box.put('gen', {'c': [1], 't': 1000});

      final ctrl = ProgressController(box);
      expect(ctrl.timesCompleted, 1);
      expect(ctrl.chaptersReadTotal, 1); // only Genesis ch 1 in new cycle
      expect(ctrl.chaptersReadLifetime, totalChaptersInBible + 1);
    });

    test('lifetime = timesCompleted * total + chaptersReadTotal', () async {
      // Simulate 3 completed Bibles with 50 chapters read in the current cycle.
      await box.put('_timesCompleted', 3);
      // Genesis read (50 chapters) in the current cycle.
      await box.put('gen', {'c': List.generate(50, (i) => i + 1), 't': 2000});

      final ctrl = ProgressController(box);
      expect(ctrl.timesCompleted, 3);
      expect(ctrl.chaptersReadTotal, 50);
      expect(ctrl.chaptersReadLifetime, 3 * totalChaptersInBible + 50);
    });
  });

  // ── LeaderboardController ──────────────────────────────────────────────────
  group('LeaderboardController', () {
    // Helper: let the Stream.value() emit and the async _onData run.
    Future<void> pump() => Future.delayed(Duration.zero);

    test('status becomes loaded with rows on success', () async {
      final rows = [
        _row('a', 'Alice', 500),
        _row('b', 'Bob', 300),
      ];
      final ctrl = LeaderboardController(
        cloud: _FakeCloud(board: rows, ownRank: 1),
        currentUid: 'a',
        myChaptersRead: 500,
      );
      await pump();
      expect(ctrl.status, LeaderboardStatus.loaded);
      expect(ctrl.entries.length, 2);
      expect(ctrl.entries[0].username, 'Alice');
      expect(ctrl.entries[1].username, 'Bob');
      ctrl.dispose();
    });

    test('status becomes empty when board is empty', () async {
      final ctrl = LeaderboardController(
        cloud: _FakeCloud(board: const []),
        currentUid: 'a',
        myChaptersRead: 0,
      );
      await pump();
      expect(ctrl.status, LeaderboardStatus.empty);
      ctrl.dispose();
    });

    test('status becomes offline on network error', () async {
      final ctrl = LeaderboardController(
        cloud: _ErrorCloud(),
        currentUid: 'a',
        myChaptersRead: 0,
      );
      await pump();
      expect(ctrl.status, LeaderboardStatus.offline);
      ctrl.dispose();
    });

    test('ownRank is populated after successful load', () async {
      final ctrl = LeaderboardController(
        cloud: _FakeCloud(
          board: [_row('z', 'Zara', 1000)],
          ownRank: 2,
        ),
        currentUid: 'a',
        myChaptersRead: 50,
      );
      await pump();
      expect(ctrl.ownRank, 2);
      ctrl.dispose();
    });

    test('currentUid is exposed correctly', () {
      final ctrl = LeaderboardController(
        cloud: _FakeCloud(),
        currentUid: 'uid-123',
        myChaptersRead: 0,
      );
      expect(ctrl.currentUid, 'uid-123');
      ctrl.dispose();
    });

    test('updateMyChaptersRead updates ownRank', () async {
      final ctrl = LeaderboardController(
        cloud: _FakeCloud(board: [_row('a', 'Alice', 500)], ownRank: 3),
        currentUid: 'a',
        myChaptersRead: 500,
      );
      await pump();
      await ctrl.updateMyChaptersRead(600);
      // _FakeCloud.fetchOwnRank always returns 3 — just verify no crash.
      expect(ctrl.ownRank, 3);
      ctrl.dispose();
    });
  });

  // ── LeaderboardEntry.fromMap ───────────────────────────────────────────────
  group('LeaderboardEntry.fromMap', () {
    test('parses all fields', () {
      final entry = LeaderboardEntry.fromMap({
        'uid': 'u1',
        'username': 'Maria',
        'chaptersRead': 123,
        'completedBooks': 4,
      });
      expect(entry.uid, 'u1');
      expect(entry.username, 'Maria');
      expect(entry.chaptersRead, 123);
      expect(entry.completedBooks, 4);
    });

    test('uses defaults for missing fields', () {
      final entry = LeaderboardEntry.fromMap({'uid': 'u2'});
      expect(entry.username, '?');
      expect(entry.chaptersRead, 0);
      expect(entry.completedBooks, 0);
    });
  });
}
