import 'package:cloud_firestore/cloud_firestore.dart';

import 'sync_merge.dart';
import 'public_profile.dart';

/// Talks to Cloud Firestore. Everything of one user lives in ONE document:
///   users/{uid} = { cycle, books: { gen: {c: [...], t: ...}, ... },
///                   username, usernameAt, completedEver: [...], maxStarsEver }
///
/// An optional PUBLIC document is written when the user opts in to the
/// leaderboard:
///   publicProfiles/{uid} = { username, chaptersRead, completedBooks,
///                            maxStars, timesCompleted, chaptersCycle,
///                            completedBookIds: [...], updatedAt }
class CloudRepository {
  CloudRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _publicDoc(String uid) =>
      _db.collection('publicProfiles').doc(uid);

  /// Reads straight from the server (throws when offline).
  Future<SyncState> fetchState(String uid) async {
    final snap = await _doc(uid).get(const GetOptions(source: Source.server));
    return SyncState.fromMap(snap.data());
  }

  /// Reads the cloud copy, merges it with [local] and writes the result back,
  /// all in one transaction so two devices cannot overwrite each other.
  /// Returns the merged result. Needs internet.
  Future<SyncState> sync(
    String uid,
    SyncState local, {
    bool showOnLeaderboard = false,
  }) async {
    final ref = _doc(uid);
    late SyncState merged;

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final remote = SyncState.fromMap(snap.data());
      merged = mergeStates(local, remote);

      final data = merged.toMap();
      tx.set(
        ref,
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        // mergeFields replaces these fields completely (so old books of a
        // finished cycle do not stay behind).
        SetOptions(mergeFields: [...data.keys, 'updatedAt']),
      );
      // Publish the merged snapshot with the private write, or remove it on
      // opt-out. A full replacement also removes any unexpected public fields.
      if (showOnLeaderboard && (merged.username?.trim().isNotEmpty ?? false)) {
        tx.set(_publicDoc(uid), {
          ...PublicProfile.fromSyncState(uid, merged).toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.delete(_publicDoc(uid));
      }
    });

    return merged;
  }

  /// A server read distinguishes a deleted/opted-out profile from cached data.
  /// Throws offline; returns null only when the server says the doc is absent.
  Future<PublicProfile?> fetchPublicProfile(String uid) async {
    final snap = await _publicDoc(
      uid,
    ).get(const GetOptions(source: Source.server));
    final data = snap.data();
    return data == null ? null : PublicProfile.fromMap(snap.id, data);
  }

  /// Removes the user's public leaderboard entry (opt-out).
  Future<void> deletePublicProfile(String uid) async {
    await _publicDoc(uid).delete();
  }

  /// Returns the top [limit] public profiles ordered by chaptersRead descending.
  Future<List<Map<String, dynamic>>> fetchLeaderboard({int limit = 50}) async {
    final snap = await _db
        .collection('publicProfiles')
        .orderBy('chaptersRead', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => {...d.data(), 'uid': d.id}).toList();
  }

  /// Returns a stream of the top [limit] public profiles ordered by
  /// chaptersRead descending, for real-time updates.
  Stream<List<Map<String, dynamic>>> leaderboardStream({int limit = 50}) {
    return _db
        .collection('publicProfiles')
        .orderBy('chaptersRead', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {...d.data(), 'uid': d.id}).toList(),
        );
  }

  /// Returns the 1-based rank of [uid] using a count() aggregate:
  /// rank = (number of profiles whose chaptersRead > myChaptersRead) + 1.
  /// Returns null when offline or when the user is not on the leaderboard.
  Future<int?> fetchOwnRank(String uid, int myChaptersRead) async {
    try {
      final agg = await _db
          .collection('publicProfiles')
          .where('chaptersRead', isGreaterThan: myChaptersRead)
          .count()
          .get();
      return (agg.count ?? 0) + 1;
    } catch (_) {
      return null;
    }
  }

  /// Returns the public profiles of users who have ever finished [bookId],
  /// limited to [limit]. Ordered by username for stable display.
  /// Returns null on any network error.
  Future<List<Map<String, dynamic>>?> fetchBookFinishers(
    String bookId, {
    int limit = 50,
  }) async {
    try {
      final snap = await _db
          .collection('publicProfiles')
          .where('completedBookIds', arrayContains: bookId)
          .limit(limit)
          .get();
      return snap.docs.map((d) => {...d.data(), 'uid': d.id}).toList();
    } catch (_) {
      return null;
    }
  }
}
