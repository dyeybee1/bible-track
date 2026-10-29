import 'package:bible_track/data/books_data.dart';
import 'package:bible_track/data/public_profile.dart';
import 'package:bible_track/data/sync_merge.dart';
import 'package:bible_track/l10n/strings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public fields mirror current-cycle stats and lifetime rank', () {
    final state = SyncState(
      cycle: 2,
      username: 'Reader',
      maxStarsEver: 10000,
      completedEver: {'gen', 'rut', 'exo'},
      books: {
        'gen': BookRecord({for (var i = 1; i <= 50; i++) i}, 1),
        'rut': BookRecord({1, 2, 3, 4}, 1),
        'exo': BookRecord({1}, 1),
      },
    );
    final profile = PublicProfile.fromSyncState('reader-id', state);
    final data = profile.toMap();
    expect(profile.uid, 'reader-id');
    expect(data, {
      'username': 'Reader',
      'chaptersRead': 2 * totalChaptersInBible + 55,
      'maxStars': 10000,
      'timesCompleted': 2,
      'chaptersCycle': 55,
      'completedBooks': 2,
      'completedBookIds': ['exo', 'gen', 'rut'],
    });
    // Serialization is an allowlist, with no stored rank or account identity.
    expect(data.keys, isNot(contains('email')));
    expect(data.keys, isNot(contains('photoURL')));
    expect(data.keys, isNot(contains('uid')));
  });

  test('public maximum is at least the lifetime count', () {
    final profile = PublicProfile.fromSyncState(
      'u',
      const SyncState(cycle: 1, books: {}, maxStarsEver: 0),
    );
    expect(profile.maxStars, totalChaptersInBible);
  });

  test(
    'legacy documents backfill until next sync, distinguishing cycle reset',
    () {
      final fullBible = PublicProfile.fromMap('u', {
        'username': 'Reader',
        'chaptersRead': totalChaptersInBible,
        'completedBooks': allBooks.length,
      });
      expect(fullBible.timesCompleted, 0);
      expect(fullBible.chaptersCycle, totalChaptersInBible);
      expect(fullBible.maxStars, totalChaptersInBible);
      final newCycle = PublicProfile.fromMap('u', {
        'username': 'Reader',
        'chaptersRead': totalChaptersInBible + 7,
        'completedBooks': 0,
      });
      expect(newCycle.timesCompleted, 1);
      expect(newCycle.chaptersCycle, 7);
    },
  );

  test('reads timestamp and trusts the document ID over any stored UID', () {
    final updated = DateTime.utc(2026, 10, 29, 12);
    final profile = PublicProfile.fromMap('actual-id', {
      'uid': 'spoofed',
      'username': 'Reader',
      'chaptersRead': 245,
      'maxStars': 500,
      'timesCompleted': 0,
      'chaptersCycle': 245,
      'completedBooks': 3,
      'updatedAt': Timestamp.fromDate(updated),
    });
    expect(profile.uid, 'actual-id');
    expect(profile.updatedAt?.isAtSameMomentAs(updated), isTrue);
    expect(profile.maxStars, 500);
  });

  test(
    'relative update times are localized with singular/plural and future clocks',
    () {
      final now = DateTime.utc(2026, 10, 29, 12);
      const en = Strings('en');
      const fil = Strings('fil');
      expect(en.profileLastUpdated(null, now: now), 'Last updated: unknown');
      expect(
        en.profileLastUpdated(now.add(const Duration(minutes: 1)), now: now),
        'Last updated: just now',
      );
      expect(
        en.profileLastUpdated(
          now.subtract(const Duration(minutes: 1)),
          now: now,
        ),
        'Last updated: 1 minute ago',
      );
      expect(
        en.profileLastUpdated(now.subtract(const Duration(hours: 2)), now: now),
        'Last updated: 2 hours ago',
      );
      expect(
        fil.profileLastUpdated(now.subtract(const Duration(days: 3)), now: now),
        'Huling update: 3 araw ang nakalipas',
      );
      expect(fil.viewProfile, 'Tingnan ang Profile');
      expect(
        en.publicProfilePrivacyNotice,
        'Your name, rank, and reading counts will be visible to other users.',
      );
    },
  );
}
