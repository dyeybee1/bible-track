import 'dart:io';

import 'package:bible_track/data/books_data.dart';
import 'package:bible_track/data/progress_controller.dart';
import 'package:bible_track/data/rank_system.dart';
import 'package:bible_track/data/sync_merge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory temp;
  late Box<dynamic> box;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('progress_rank_');
    Hive.init(temp.path);
    box = await Hive.openBox<dynamic>('progress');
  });
  tearDown(() async {
    await box.flush();
    await Hive.close();
    await temp.delete(recursive: true);
  });

  test(
    'first launch backfills from lifetime chapters and persists on disk',
    () async {
      await box.put('_timesCompleted', 2);
      await box.put('gen', {
        'c': [1, 2, 3],
        't': 1,
      });
      final progress = ProgressController(box);
      final expected = 2 * totalChaptersInBible + 3;
      expect(progress.maxStarsEver, expected);
      expect(box.get('_maxStarsEver'), expected);
      progress.dispose();
      await box.close();
      box = await Hive.openBox<dynamic>('progress');
      final reopened = ProgressController(box);
      expect(reopened.maxStarsEver, expected);
      reopened.dispose();
    },
  );

  test('read gains one star; unmark demotes quietly and preserves peak', () {
    final progress = ProgressController(box);
    final book = allBooks.first;
    progress.markUpTo(book, 9);
    progress.markChapterRead(book, 10);
    expect(progress.chaptersReadLifetime, 10);
    expect(progress.maxStarsEver, 10);
    expect(
      rankForStars(progress.chaptersReadLifetime).division,
      RankDivision.ii,
    );
    progress.toggleChapter(book, 10);
    expect(progress.chaptersReadLifetime, 9);
    expect(
      rankForStars(progress.chaptersReadLifetime).division,
      RankDivision.iii,
    );
    expect(progress.maxStarsEver, 10);
    progress.clearBook(book);
    expect(progress.chaptersReadLifetime, 0);
    expect(progress.maxStarsEver, 10);
    expect(ProgressController(box).maxStarsEver, 10);
    progress.dispose();
  });

  test('markAll and startNewCycle preserve peak and lifetime star count', () {
    final progress = ProgressController(box);
    for (final book in allBooks) {
      progress.markAll(book);
    }
    expect(progress.maxStarsEver, totalChaptersInBible);
    progress.startNewCycle();
    expect(progress.chaptersReadTotal, 0);
    expect(progress.chaptersReadLifetime, totalChaptersInBible);
    expect(progress.maxStarsEver, totalChaptersInBible);
    progress.markChapterRead(allBooks.first, 1);
    expect(progress.maxStarsEver, totalChaptersInBible + 1);
    progress.toggleChapter(allBooks.first, 1);
    expect(progress.maxStarsEver, totalChaptersInBible + 1);
    progress.dispose();
  });

  test(
    'existing higher maximum survives launch; stale maximum is repaired',
    () async {
      await box.put('_maxStarsEver', 200);
      await box.put('gen', {
        'c': [1],
        't': 1,
      });
      final progress = ProgressController(box);
      expect(progress.maxStarsEver, 200);
      progress.dispose();
      await box.put('_maxStarsEver', 0);
      final repaired = ProgressController(box);
      expect(repaired.maxStarsEver, 1);
      expect(box.get('_maxStarsEver'), 1);
      repaired.dispose();
    },
  );

  test(
    'merge keeps higher peak, recomputes lifetime, and notifies observers',
    () {
      final progress = ProgressController(box);
      var notifications = 0;
      progress.addListener(() => notifications++);
      expect(progress.applyMerge(0, {}, {}, mergedMaxStarsEver: 500), isTrue);
      expect(notifications, 1);
      expect(progress.maxStarsEver, 500);
      expect(progress.applyMerge(0, {}, {}, mergedMaxStarsEver: 10), isFalse);
      expect(notifications, 1);
      progress.applyMerge(1, {
        'gen': BookRecord({1}, 1),
      }, {});
      expect(progress.maxStarsEver, totalChaptersInBible + 1);
      expect(box.get('_maxStarsEver'), totalChaptersInBible + 1);
      progress.dispose();
    },
  );

  test('merge preserves a newer local peak and in-flight chapter changes', () {
    final progress = ProgressController(box);
    final baseline = progress.exportRecords();
    progress.markUpTo(allBooks.first, 20);
    progress.applyMerge(
      0,
      {'gen': BookRecord({}, 0)},
      baseline,
      mergedMaxStarsEver: 10,
    );
    expect(progress.chaptersReadLifetime, 20);
    expect(progress.maxStarsEver, 20);
    progress.dispose();
  });

  test('switching account clears only the old account local maximum', () {
    final progress = ProgressController(box);
    progress.markUpTo(allBooks.first, 20);
    progress.wipeLocal();
    expect(progress.maxStarsEver, 0);
    expect(progress.chaptersReadLifetime, 0);
    progress.applyMerge(0, {}, {}, mergedMaxStarsEver: 75);
    expect(progress.maxStarsEver, 75);
    progress.dispose();
  });
}
