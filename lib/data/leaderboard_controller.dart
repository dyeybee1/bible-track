import 'dart:async';

import 'package:flutter/foundation.dart';

import 'cloud_repository.dart';

/// A single row in the leaderboard.
@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.username,
    required this.chaptersRead,
    required this.completedBooks,
  });

  final String uid;
  final String username;
  final int chaptersRead;
  final int completedBooks;

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      uid: map['uid'] as String? ?? '',
      username: map['username'] as String? ?? '?',
      chaptersRead: (map['chaptersRead'] as num?)?.toInt() ?? 0,
      completedBooks: (map['completedBooks'] as num?)?.toInt() ?? 0,
    );
  }
}

/// What the leaderboard screen shows.
enum LeaderboardStatus { loading, loaded, offline, empty }

/// Streams the top-50 leaderboard live from Firestore and exposes the
/// current user's own rank (fetched once per stream event).
///
/// Uses [ChangeNotifier] to match the rest of the app's conventions.
class LeaderboardController extends ChangeNotifier {
  LeaderboardController({
    required CloudRepository cloud,
    required String currentUid,
    required int myChaptersRead,
  })  : _cloud = cloud,
        _currentUid = currentUid,
        _myChaptersRead = myChaptersRead {
    _subscribe();
  }

  final CloudRepository _cloud;
  final String _currentUid;
  int _myChaptersRead;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  LeaderboardStatus _status = LeaderboardStatus.loading;
  List<LeaderboardEntry> _entries = const [];
  int? _ownRank; // null = loading, -1 = offline/unknown

  LeaderboardStatus get status => _status;
  List<LeaderboardEntry> get entries => _entries;

  /// 1-based rank. Null while loading, -1 when unavailable.
  int? get ownRank => _ownRank;

  String get currentUid => _currentUid;

  // ── Live stream subscription ───────────────────────────────────────────────

  void _subscribe() {
    _status = LeaderboardStatus.loading;
    _sub?.cancel();
    _sub = _cloud.leaderboardStream(limit: 50).listen(
      _onData,
      onError: _onError,
    );
  }

  Future<void> _onData(List<Map<String, dynamic>> rows) async {
    _entries = rows.map(LeaderboardEntry.fromMap).toList();
    _status =
        _entries.isEmpty ? LeaderboardStatus.empty : LeaderboardStatus.loaded;
    notifyListeners();

    // Fetch own rank asynchronously — doesn't block the stream event.
    try {
      _ownRank = await _cloud.fetchOwnRank(_currentUid, _myChaptersRead);
    } catch (_) {
      _ownRank = -1;
    }
    notifyListeners();
  }

  void _onError(Object _) {
    _status = LeaderboardStatus.offline;
    notifyListeners();
  }

  /// Updates [myChaptersRead] and re-fetches the own-rank immediately.
  /// Call this when the user's progress changes.
  Future<void> updateMyChaptersRead(int chaptersRead) async {
    if (_myChaptersRead == chaptersRead) return;
    _myChaptersRead = chaptersRead;
    try {
      _ownRank = await _cloud.fetchOwnRank(_currentUid, _myChaptersRead);
    } catch (_) {
      _ownRank = -1;
    }
    notifyListeners();
  }

  /// Forces a manual reload (e.g. tapping Retry after an offline error).
  void reload() => _subscribe();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
