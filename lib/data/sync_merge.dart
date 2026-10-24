import 'dart:math' as math;

/// What was read in one book, plus when it was last changed on a device.
class BookRecord {
  const BookRecord(this.chapters, this.updatedAt);

  final Set<int> chapters;

  /// Milliseconds since epoch (device clock). Used to decide which copy wins.
  final int updatedAt;

  Map<String, dynamic> toMap() => {
    'c': (chapters.toList()..sort()),
    't': updatedAt,
  };

  factory BookRecord.fromMap(Map<dynamic, dynamic> map) {
    final c = map['c'];
    final t = map['t'];
    return BookRecord(
      c is List ? c.whereType<num>().map((e) => e.toInt()).toSet() : <int>{},
      t is num ? t.toInt() : 0,
    );
  }
}

/// Everything that is synced to the cloud (one Firestore document per user).
class SyncState {
  const SyncState({
    required this.cycle,
    required this.books,
    this.username,
    this.usernameAt = 0,
    this.completedEver = const {},
  });

  /// How many times the whole Bible was finished. Progress always belongs to
  /// the current cycle; progress of an older cycle is ignored.
  final int cycle;
  final Map<String, BookRecord> books;
  final String? username;
  final int usernameAt;

  /// Set of book ids ever completed by this user (across all cycles).
  /// Merged by UNION so it can only grow.
  final Set<String> completedEver;

  Map<String, dynamic> toMap() => {
    'cycle': cycle,
    'books': {for (final e in books.entries) e.key: e.value.toMap()},
    if (username != null) 'username': username,
    'usernameAt': usernameAt,
    'completedEver': completedEver.toList(),
  };

  factory SyncState.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const SyncState(cycle: 0, books: {});
    final books = <String, BookRecord>{};
    final raw = data['books'];
    if (raw is Map) {
      raw.forEach((key, value) {
        if (key is String && value is Map) {
            books[key] = BookRecord.fromMap(value);
          }
      });
    }
    final cycle = data['cycle'];
    final name = data['username'];
    final at = data['usernameAt'];

    final rawEver = data['completedEver'];
    final completedEver = <String>{};
    if (rawEver is List) {
      completedEver.addAll(rawEver.whereType<String>());
    }

    return SyncState(
      cycle: cycle is num ? cycle.toInt() : 0,
      books: books,
      username: name is String ? name : null,
      usernameAt: at is num ? at.toInt() : 0,
      completedEver: completedEver,
    );
  }
}

/// Combines the copy on this phone with the copy in the cloud.
///
/// Rules:
///  1. The higher cycle wins. Progress that belongs to a lower cycle is dropped
///     (it was part of a finished Bible that was already restarted somewhere).
///  2. For each book, the copy that was changed last wins. When both were
///     changed at the same moment, the chapters are combined (union).
///  3. The username that was changed last wins.
///  4. completedEver is always the UNION of both sides — it can only grow.
SyncState mergeStates(SyncState local, SyncState remote) {
  final cycle = math.max(local.cycle, remote.cycle);
  final l = local.cycle == cycle ? local.books : const <String, BookRecord>{};
  final r = remote.cycle == cycle ? remote.books : const <String, BookRecord>{};

  final books = <String, BookRecord>{};
  for (final id in {...l.keys, ...r.keys}) {
    final a = l[id];
    final b = r[id];
    if (a == null) {
      books[id] = b!;
    } else if (b == null) {
      books[id] = a;
    } else if (a.updatedAt > b.updatedAt) {
      books[id] = a;
    } else if (b.updatedAt > a.updatedAt) {
      books[id] = b;
    } else {
      books[id] = BookRecord(a.chapters.union(b.chapters), a.updatedAt);
    }
  }

  String? username;
  var usernameAt = 0;
  if (remote.username != null &&
      (local.username == null || remote.usernameAt > local.usernameAt)) {
    username = remote.username;
    usernameAt = remote.usernameAt;
  } else {
    username = local.username;
    usernameAt = local.usernameAt;
  }

  // completedEver: union of both sides — never shrinks.
  final completedEver = {...local.completedEver, ...remote.completedEver};

  return SyncState(
    cycle: cycle,
    books: books,
    username: username,
    usernameAt: usernameAt,
    completedEver: completedEver,
  );
}
