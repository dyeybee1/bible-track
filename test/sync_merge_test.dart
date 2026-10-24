import 'package:bible_track/data/sync_merge.dart';
import 'package:flutter_test/flutter_test.dart';

BookRecord rec(List<int> chapters, int t) => BookRecord(chapters.toSet(), t);

void main() {
  test('the copy that changed last wins for a book', () {
    final local = SyncState(
      cycle: 0,
      books: {
        'gen': rec([1, 2], 200),
      },
    );
    final remote = SyncState(
      cycle: 0,
      books: {
        'gen': rec([1, 2, 3], 100),
      },
    );
    final merged = mergeStates(local, remote);
    expect(merged.books['gen']!.chapters, {1, 2}); // local is newer
  });

  test('a chapter that was unmarked stays unmarked', () {
    final local = SyncState(
      cycle: 0,
      books: {
        'gen': rec([1], 300),
      },
    );
    final remote = SyncState(
      cycle: 0,
      books: {
        'gen': rec([1, 2], 200),
      },
    );
    expect(mergeStates(local, remote).books['gen']!.chapters, {1});
  });

  test('different books from two devices are both kept', () {
    final local = SyncState(
      cycle: 0,
      books: {
        'gen': rec([1], 100),
      },
    );
    final remote = SyncState(
      cycle: 0,
      books: {
        'exo': rec([4], 100),
      },
    );
    final merged = mergeStates(local, remote);
    expect(merged.books.keys.toSet(), {'gen', 'exo'});
  });

  test('same time: chapters are combined', () {
    final local = SyncState(
      cycle: 0,
      books: {
        'gen': rec([1, 2], 100),
      },
    );
    final remote = SyncState(
      cycle: 0,
      books: {
        'gen': rec([2, 3], 100),
      },
    );
    expect(mergeStates(local, remote).books['gen']!.chapters, {1, 2, 3});
  });

  test('progress of an older cycle is dropped (local is older)', () {
    final local = SyncState(
      cycle: 0,
      books: {
        'gen': rec([1, 2, 3], 999),
      },
    );
    final remote = SyncState(
      cycle: 1,
      books: {
        'exo': rec([1], 100),
      },
    );
    final merged = mergeStates(local, remote);
    expect(merged.cycle, 1);
    expect(merged.books.keys.toSet(), {'exo'});
  });

  test('progress of an older cycle is dropped (cloud is older)', () {
    final local = SyncState(cycle: 1, books: const {});
    final remote = SyncState(
      cycle: 0,
      books: {
        'gen': rec([1, 2, 3], 999),
      },
    );
    final merged = mergeStates(local, remote);
    expect(merged.cycle, 1);
    expect(merged.books, isEmpty);
  });

  test('the newest username wins', () {
    const local = SyncState(
      cycle: 0,
      books: {},
      username: 'Juan',
      usernameAt: 100,
    );
    const remote = SyncState(
      cycle: 0,
      books: {},
      username: 'Juanito',
      usernameAt: 200,
    );
    expect(mergeStates(local, remote).username, 'Juanito');
  });

  test('a new phone takes the username from the cloud', () {
    const local = SyncState(cycle: 0, books: {});
    const remote = SyncState(
      cycle: 0,
      books: {},
      username: 'Maria',
      usernameAt: 50,
    );
    expect(mergeStates(local, remote).username, 'Maria');
  });

  test('toMap and fromMap give the same data back', () {
    final state = SyncState(
      cycle: 2,
      books: {
        'gen': rec([3, 1, 2], 10),
      },
      username: 'Ana',
      usernameAt: 5,
      completedEver: {'gen', 'exo'},
    );
    final back = SyncState.fromMap(state.toMap());
    expect(back.cycle, 2);
    expect(back.books['gen']!.chapters, {1, 2, 3});
    expect(back.username, 'Ana');
    expect(back.usernameAt, 5);
    expect(back.completedEver, {'gen', 'exo'});
  });

  test('completedEver is the union of local and remote', () {
    final local = SyncState(
      cycle: 0,
      books: {},
      completedEver: {'gen', 'exo'},
    );
    final remote = SyncState(
      cycle: 0,
      books: {},
      completedEver: {'exo', 'lev'},
    );
    final merged = mergeStates(local, remote);
    expect(merged.completedEver, {'gen', 'exo', 'lev'});
  });

  test('completedEver is preserved across a cycle jump', () {
    final local = SyncState(
      cycle: 0,
      books: {'gen': rec([1], 100)},
      completedEver: {'gen'},
    );
    final remote = SyncState(
      cycle: 1,
      books: {},
      completedEver: {'gen', 'exo'},
    );
    final merged = mergeStates(local, remote);
    expect(merged.cycle, 1);
    expect(merged.completedEver, {'gen', 'exo'}); // union, not reset
  });

  test('completedEver defaults to empty when field is absent in Firestore doc', () {
    final state = SyncState.fromMap({'cycle': 0, 'books': {}});
    expect(state.completedEver, isEmpty);
  });
}
