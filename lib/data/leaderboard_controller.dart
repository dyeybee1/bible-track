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

/// Fetches and exposes the top-50 leaderboard plus the current user's own rank.
///
/// Uses [ChangeNotifier] to match the rest of the app's conventions.
class LeaderboardController extends ChangeNotifier {
  LeaderboardController({
    required CloudRepository cloud,
    required String currentUid,
    required int myChaptersRead,
  })  : _cloud = cloud,
        _currentUid = currentUid,
        _myChaptersRead = myChaptersRead;

  final CloudRepository _cloud;
  final String _currentUid;
  final int _myChaptersRead;

  LeaderboardStatus _status = LeaderboardStatus.loading;
  List<LeaderboardEntry> _entries = const [];
  int? _ownRank; // null = still loading, -1 = error/offline

  LeaderboardStatus get status => _status;
  List<LeaderboardEntry> get entries => _entries;

  /// 1-based rank of the current user. Null while loading, -1 when unavailable.
  int? get ownRank => _ownRank;

  String get currentUid => _currentUid;

  /// Loads the top-50 list and the current user's own rank.
  Future<void> load() async {
    _status = LeaderboardStatus.loading;
    notifyListeners();

    try {
      final rows = await _cloud.fetchLeaderboard(limit: 50);
      _entries = rows.map(LeaderboardEntry.fromMap).toList();
      _status =
          _entries.isEmpty ? LeaderboardStatus.empty : LeaderboardStatus.loaded;
    } catch (_) {
      _status = LeaderboardStatus.offline;
      notifyListeners();
      return;
    }

    // Fetch own rank even if outside top 50.
    _ownRank = await _cloud.fetchOwnRank(_currentUid, _myChaptersRead);
    notifyListeners();
  }
}
