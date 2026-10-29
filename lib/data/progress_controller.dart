import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../models/book.dart';
import 'books_data.dart';
import 'sync_merge.dart';

/// Keeps track of which chapters were read and saves them on the phone.
///
/// Storage layout (one Hive box called 'progress'):
///   key = book id (e.g. 'gen'), value = {'c': [chapters read], 't': last change}
///   key = '_timesCompleted',    value = how many times the whole Bible was finished
///   key = '_completedEver',     value = List<String> of book ids ever fully read
///   key = '_maxStarsEver',      value = highest lifetime chapter count
///
/// A book that was cleared keeps an empty record (with its time), so the
/// cloud can tell "cleared on purpose" apart from "never touched".
class ProgressController extends ChangeNotifier {
  ProgressController(this._box) {
    for (final key in _box.keys) {
      if (key is! String ||
          key == _timesKey ||
          key == _completedEverKey ||
          key == _maxStarsKey) {
        continue;
      }
      final value = _box.get(key);
      if (value is Map) {
        final record = BookRecord.fromMap(value);
        _read[key] = record.chapters;
        _stamp[key] = record.updatedAt;
      } else if (value is List) {
        // older format (before syncing existed)
        _read[key] = value.whereType<int>().toSet();
        _stamp[key] = 0;
      }
    }
    final times = _box.get(_timesKey);
    if (times is int) _times = times;

    // Load persisted completedEver set.
    final ever = _box.get(_completedEverKey);
    if (ever is List) {
      _completedEver.addAll(ever.whereType<String>());
    }

    // Back-fill: if a book is currently fully read but not in _completedEver
    // yet (first launch after the feature was added), add it now.
    for (final book in allBooks) {
      if (_isCurrentlyCompleted(book) && !_completedEver.contains(book.id)) {
        _completedEver.add(book.id);
      }
    }
    _persistCompletedEver();
    final highest = _box.get(_maxStarsKey);
    // First-launch backfill also repairs a stale stored high-water mark.
    _maxStarsEver = highest is int && highest > chaptersReadLifetime
        ? highest
        : chaptersReadLifetime;
    _box.put(_maxStarsKey, _maxStarsEver);
  }

  static const String _timesKey = '_timesCompleted';
  static const String _completedEverKey = '_completedEver';
  static const String _maxStarsKey = '_maxStarsEver';

  final Box<dynamic> _box;
  final Map<String, Set<int>> _read = {};
  final Map<String, int> _stamp = {};
  int _times = 0;
  int _maxStarsEver = 0;

  /// Highest lifetime chapter count for this account, preserved across cycles.
  int get maxStarsEver => _maxStarsEver;

  /// Book ids that the user has EVER fully read (across all cycles).
  /// Never shrinks — not cleared by startNewCycle or clearBook.
  final Set<String> _completedEver = {};

  // ---- reading ----

  Set<int> chaptersRead(String bookId) => _read[bookId] ?? const <int>{};

  int readCount(Book b) => chaptersRead(b.id).length;

  bool _isCurrentlyCompleted(Book b) => readCount(b) >= b.totalChapters;

  bool isCompleted(Book b) => _isCurrentlyCompleted(b);

  double progress(Book b) =>
      b.totalChapters == 0 ? 0 : readCount(b) / b.totalChapters;

  int completedIn(Iterable<Book> books) => books.where(isCompleted).length;

  // ---- numbers for the profile ----

  /// How many times the whole Bible was finished. Also the "cycle" number
  /// used when syncing.
  int get timesCompleted => _times;
  int get cycle => _times;

  int get completedBooks => completedIn(allBooks);

  int get chaptersReadTotal =>
      _read.values.fold<int>(0, (sum, set) => sum + set.length);

  /// Total chapters read across ALL completed Bible cycles plus the current
  /// cycle. This is the value stored on the public leaderboard.
  int get chaptersReadLifetime =>
      _times * totalChaptersInBible + chaptersReadTotal;

  bool get allBooksCompleted => completedBooks == allBooks.length;

  /// Set of book ids the user has fully read at any point (across all cycles).
  /// Never cleared — monotonically grows. Used for the "who finished this
  /// book" feature on the chapter screen.
  Set<String> get completedEver => Set.unmodifiable(_completedEver);

  // ---- changing ----

  void toggleChapter(Book b, int chapter) {
    if (chapter < 1 || chapter > b.totalChapters) return;
    final set = _read.putIfAbsent(b.id, () => <int>{});
    if (!set.remove(chapter)) set.add(chapter);
    _afterWrite(b);
  }

  /// Marks chapters 1..[chapter] as read.
  void markUpTo(Book b, int chapter) {
    final last = chapter.clamp(0, b.totalChapters);
    final set = _read.putIfAbsent(b.id, () => <int>{});
    for (var c = 1; c <= last; c++) {
      set.add(c);
    }
    _afterWrite(b);
  }

  void markAll(Book b) => markUpTo(b, b.totalChapters);

  /// Marks exactly one chapter as read. Used by the quiz on a passing attempt.
  /// Does nothing if the chapter is already read.
  void markChapterRead(Book b, int chapter) {
    if (chapter < 1 || chapter > b.totalChapters) return;
    final set = _read.putIfAbsent(b.id, () => <int>{});
    if (set.contains(chapter)) return; // already read, no-op
    set.add(chapter);
    _afterWrite(b);
  }

  void clearBook(Book b) {
    _read[b.id] = <int>{};
    // completedEver is intentionally NOT touched here.
    _save(b);
  }

  /// Only works when every book is finished: adds 1 to the "times completed"
  /// counter and makes every book unread again.
  /// completedEver is NOT cleared — it persists across cycles.
  void startNewCycle() {
    if (!allBooksCompleted) return;
    _wipeBooks();
    _times++;
    _box.put(_timesKey, _times);
    _updateMaxStars();
    notifyListeners();
  }

  // ---- syncing ----

  /// A copy of everything that is read, for the cloud merge.
  Map<String, BookRecord> exportRecords() => {
    for (final e in _read.entries)
      e.key: BookRecord({...e.value}, _stamp[e.key] ?? 0),
  };

  /// Puts the merged result from the cloud on this phone.
  /// [baseline] is what [exportRecords] returned when the sync started: a book
  /// that was changed on this phone in the meantime is left alone and goes up
  /// with the next sync.
  bool applyMerge(
    int cycle,
    Map<String, BookRecord> merged,
    Map<String, BookRecord> baseline, {
    Set<String>? mergedCompletedEver,
    int mergedMaxStarsEver = 0,
  }) {
    var changed = false;

    final cycleJumped = cycle > _times;
    if (cycleJumped) {
      // The Bible was finished and restarted on another device.
      _wipeBooks();
      _times = cycle;
      _box.put(_timesKey, _times);
      changed = true;
    }

    for (final e in merged.entries) {
      final id = e.key;
      final record = e.value;

      if (!cycleJumped) {
        final nowStamp = _read.containsKey(id) ? (_stamp[id] ?? 0) : -1;
        final thenStamp = baseline.containsKey(id)
            ? baseline[id]!.updatedAt
            : -1;
        if (nowStamp != thenStamp) continue; // changed during the sync
      }

      final same =
          _read.containsKey(id) &&
          _stamp[id] == record.updatedAt &&
          setEquals(_read[id], record.chapters);
      if (same) continue;

      _read[id] = {...record.chapters};
      _stamp[id] = record.updatedAt;
      _persist(id);
      changed = true;
    }

    // Merge completedEver (union) if provided by the cloud.
    if (mergedCompletedEver != null &&
        !mergedCompletedEver.every(_completedEver.contains)) {
      _completedEver.addAll(mergedCompletedEver);
      _persistCompletedEver();
      changed = true;
    }

    if (_updateMaxStars(mergedMaxStarsEver)) changed = true;
    if (changed) notifyListeners();
    return changed;
  }

  /// Forgets everything on this phone (used when another Google account logs in).
  void wipeLocal() {
    _wipeBooks();
    _times = 0;
    _box.delete(_timesKey);
    _completedEver.clear();
    _box.delete(_completedEverKey);
    // Account switching clears this account's private high-water mark too.
    _maxStarsEver = 0;
    _box.delete(_maxStarsKey);
    notifyListeners();
  }

  // ---- storage ----

  void _wipeBooks() {
    _box.deleteAll(_read.keys.toList());
    _read.clear();
    _stamp.clear();
  }

  void _persist(String id) {
    _box.put(id, BookRecord(_read[id] ?? <int>{}, _stamp[id] ?? 0).toMap());
  }

  void _persistCompletedEver() {
    _box.put(_completedEverKey, _completedEver.toList());
  }

  bool _updateMaxStars([int mergedMax = 0]) {
    final highest = [
      _maxStarsEver,
      mergedMax,
      chaptersReadLifetime,
    ].reduce((a, b) => a > b ? a : b);
    if (highest == _maxStarsEver) return false;
    _maxStarsEver = highest;
    _box.put(_maxStarsKey, highest);
    return true;
  }

  // Called after any chapter write — persists the book and updates completedEver.
  void _afterWrite(Book b) {
    _save(b);
    if (_isCurrentlyCompleted(b) && _completedEver.add(b.id)) {
      _persistCompletedEver();
      // notifyListeners already called by _save; no double-notify needed.
    }
  }

  // A book is "completed" automatically when every chapter is in the set,
  // so there is nothing extra to store for it.
  void _save(Book b) {
    _stamp[b.id] = DateTime.now().millisecondsSinceEpoch;
    _persist(b.id);
    _updateMaxStars();
    notifyListeners();
  }
}
