import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'books_data.dart';
import 'sync_merge.dart';

/// Only the reading information an opted-in user shares with other readers.
/// The UID comes from the document ID, never from a stored profile field.
class PublicProfile {
  const PublicProfile({
    required this.uid,
    required this.username,
    required this.chaptersRead,
    required this.maxStars,
    required this.timesCompleted,
    required this.chaptersCycle,
    required this.completedBooks,
    this.completedBookIds = const {},
    this.updatedAt,
  });

  final String uid;
  final String username;
  final int chaptersRead;
  final int maxStars;
  final int timesCompleted;
  final int chaptersCycle;
  final int completedBooks;
  final Set<String> completedBookIds;
  final DateTime? updatedAt;

  factory PublicProfile.fromSyncState(String uid, SyncState state) {
    final chaptersCycle = state.books.values.fold<int>(
      0,
      (totalRead, book) => totalRead + book.chapters.length,
    );
    return PublicProfile(
      uid: uid,
      username: state.username ?? '',
      chaptersRead: state.chaptersReadLifetime,
      maxStars: math.max(state.maxStarsEver, state.chaptersReadLifetime),
      timesCompleted: state.cycle,
      chaptersCycle: chaptersCycle,
      completedBooks: allBooks
          .where(
            (book) =>
                (state.books[book.id]?.chapters.length ?? 0) >=
                book.totalChapters,
          )
          .length,
      completedBookIds: state.completedEver,
    );
  }

  factory PublicProfile.fromMap(String uid, Map<String, dynamic> data) {
    final read = (data['chaptersRead'] as num?)?.toInt() ?? 0;
    final books = (data['completedBooks'] as num?)?.toInt() ?? 0;
    // Older public documents have lifetime chapters and current-cycle books.
    // A fully read current Bible has not been counted as a completed cycle yet.
    final legacyCycle = math.max(
      0,
      (read - (books == allBooks.length ? totalChaptersInBible : 0)) ~/
          totalChaptersInBible,
    );
    final times = (data['timesCompleted'] as num?)?.toInt() ?? legacyCycle;
    final updated = data['updatedAt'];
    return PublicProfile(
      uid: uid,
      username: data['username'] as String? ?? '',
      chaptersRead: read,
      maxStars: math.max((data['maxStars'] as num?)?.toInt() ?? read, read),
      timesCompleted: times,
      chaptersCycle:
          (data['chaptersCycle'] as num?)?.toInt() ??
          math.max(0, read - times * totalChaptersInBible),
      completedBooks: books,
      completedBookIds:
          (data['completedBookIds'] as List?)?.whereType<String>().toSet() ??
          const {},
      updatedAt: updated is Timestamp
          ? updated.toDate()
          : updated is DateTime
          ? updated
          : null,
    );
  }

  /// Explicit allowlist: no private account data can enter the public document.
  Map<String, dynamic> toMap() => {
    'username': username,
    'chaptersRead': chaptersRead,
    'maxStars': maxStars,
    'timesCompleted': timesCompleted,
    'chaptersCycle': chaptersCycle,
    'completedBooks': completedBooks,
    'completedBookIds': completedBookIds.toList()..sort(),
    if (updatedAt != null) 'updatedAt': updatedAt,
  };
}
