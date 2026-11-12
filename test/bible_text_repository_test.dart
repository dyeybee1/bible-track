import 'dart:convert';
import 'dart:io';

import 'package:bible_track/data/bible_text_repository.dart';
import 'package:bible_track/data/books_data.dart';
import 'package:bible_track/data/settings_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

class _Files extends CachingAssetBundle {
  final reads = <String, int>{};
  String? failOnce;

  @override
  Future<ByteData> load(String key) async {
    reads.update(key, (n) => n + 1, ifAbsent: () => 1);
    if (failOnce == key) {
      failOnce = null;
      throw StateError('temporary read failure');
    }
    return ByteData.sublistView(await File(key).readAsBytes());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registered rootBundle assets load a literal offline chapter', () async {
    final verses = await BibleTextRepository().loadChapter(
      'gen',
      1,
      BibleTranslation.web,
    );
    expect(verses, hasLength(31));
    expect(
      verses.first.text,
      'In the beginning, God created the heavens and the earth.',
    );
    expect(() => verses.clear(), throwsUnsupportedError);
  });

  test(
    'loads books lazily, shares concurrent reads, retries failed asset loads',
    () async {
      final files = _Files();
      final repo = BibleTextRepository(bundle: files);
      await Future.wait([
        repo.loadChapter('gen', 1, BibleTranslation.web),
        repo.loadChapter('gen', 2, BibleTranslation.web),
      ]);
      expect(files.reads, {
        'assets/bible/mapping.json': 1,
        'assets/bible/web/gen.json': 1,
      });
      files.failOnce = 'assets/bible/web/exo.json';
      await expectLater(
        repo.loadChapter('exo', 1, BibleTranslation.web),
        throwsStateError,
      );
      expect(
        await repo.loadChapter('exo', 1, BibleTranslation.web),
        isNotEmpty,
      );
      expect(files.reads['assets/bible/web/exo.json'], 2);
    },
  );

  test('Joel and Malachi mappings apply once and start at verse 1', () async {
    final repo = BibleTextRepository(bundle: _Files());
    for (final t in BibleTranslation.values) {
      final joel2 = await repo.loadChapter('joe', 2, t);
      final joel3 = await repo.loadChapter('joe', 3, t);
      final joel4 = await repo.loadChapter('joe', 4, t);
      final malachi = await repo.loadChapter('mal', 3, t);
      expect(joel2, hasLength(27));
      expect(joel3.map((v) => v.number), orderedEquals([1, 2, 3, 4, 5]));
      expect(
        joel4.map((v) => v.number),
        orderedEquals(List.generate(21, (i) => i + 1)),
      );
      expect(
        malachi.map((v) => v.number),
        orderedEquals(List.generate(24, (i) => i + 1)),
      );
    }
    expect(
      (await repo.loadChapter('joe', 3, BibleTranslation.web)).first.text,
      contains('pour out my Spirit'),
    );
  });

  test('availability and fallback use whole APP chapters', () async {
    final repo = BibleTextRepository(bundle: _Files());
    for (final book in allBooks.where((b) => b.isDeutero)) {
      expect(availableTranslations(book.id, 1), [BibleTranslation.web]);
    }
    for (final chapter in [3, 13, 14]) {
      expect(availableTranslations('dan', chapter), [BibleTranslation.web]);
      final fallback = await repo.loadChapter(
        'dan',
        chapter,
        BibleTranslation.tl1905,
      );
      final english = await repo.loadChapter(
        'dan',
        chapter,
        BibleTranslation.web,
      );
      expect(
        fallback.map((v) => v.text),
        orderedEquals(english.map((v) => v.text)),
      );
    }
    for (var chapter = 10; chapter <= 16; chapter++) {
      expect(availableTranslations('est', chapter), [BibleTranslation.web]);
    }
    expect(availableTranslations('est', 9), BibleTranslation.values);
    expect(availableTranslations('dan', 4), BibleTranslation.values);
    expect(
      (await repo.loadChapter('bar', 6, BibleTranslation.tl1905)),
      hasLength(73),
    );
  });

  test(
    'Daniel additions, Sirach and Psalm verse counts match boundary report',
    () async {
      final repo = BibleTextRepository(bundle: _Files());
      for (final row in [
        ('dan', 3, 100),
        ('dan', 4, 34),
        ('dan', 13, 64),
        ('dan', 14, 42),
        ('sir', 51, 30),
        ('psa', 51, 19),
        ('psa', 119, 176),
      ]) {
        final verses = await repo.loadChapter(
          row.$1,
          row.$2,
          BibleTranslation.web,
        );
        expect(verses, hasLength(row.$3), reason: '${row.$1} ${row.$2}');
        expect(verses.first.number, 1);
      }
    },
  );

  test(
    'Esther literal spans keep Vulgate-style additions without duplication',
    () async {
      final repo = BibleTextRepository(bundle: _Files());
      for (final row in [
        (10, 13),
        (11, 12),
        (12, 6),
        (13, 18),
        (14, 19),
        (16, 24),
      ]) {
        final verses = await repo.loadChapter(
          'est',
          row.$1,
          BibleTranslation.web,
        );
        expect(verses, hasLength(row.$2));
        expect(
          verses.map((v) => v.number),
          orderedEquals(List.generate(row.$2, (i) => i + 1)),
        );
      }
      final chapter1 = await repo.loadChapter('est', 1, BibleTranslation.web);
      expect(chapter1.first.text, isNot(contains('saw a vision')));
      expect(
        (await repo.loadChapter('est', 11, BibleTranslation.web)).first.text,
        startsWith('In the fourth year'),
      );
      expect(
        (await repo.loadChapter('est', 12, BibleTranslation.web)).first.text,
        startsWith('Mordecai rested quietly'),
      );
      final chapter8 = await repo.loadChapter('est', 8, BibleTranslation.web);
      expect(chapter8[12].text, startsWith('Let the copies be posted'));
    },
  );

  test('every app chapter is nonempty or explicitly text pending', () async {
    final repo = BibleTextRepository(bundle: _Files());
    final pending = <String>{};
    for (final book in allBooks) {
      for (var ch = 1; ch <= book.totalChapters; ch++) {
        for (final t in availableTranslations(book.id, ch)) {
          try {
            final verses = await repo.loadChapter(book.id, ch, t);
            expect(verses, isNotEmpty, reason: '${book.id}/$ch/$t');
            expect(verses.every((v) => v.text.trim().isNotEmpty), isTrue);
          } on BibleTextPendingException {
            pending.add('${book.id}/$ch/${t.name}');
          }
        }
      }
    }
    expect(pending, {'est/5/web', 'est/15/web'});
    await expectLater(
      repo.loadChapter('est', 15, BibleTranslation.tl1905),
      throwsA(isA<BibleTextPendingException>()),
    );
  });

  test(
    'bundled mapping equals reviewed tooling mapping, with flags retained',
    () async {
      final bundled = jsonDecode(
        await rootBundle.loadString('assets/bible/mapping.json'),
      );
      final reviewed = jsonDecode(
        await File('tools/bible_mapping.json').readAsString(),
      );
      expect(bundled, reviewed);
      expect(
        reviewed['translations']['web']['books']['est']['review_required_chapters'],
        [1, 3, 5, 8, 11, 12, 13, 15, 16],
      );
    },
  );

  test(
    'reader preferences default by language, persist locally and stay clamped',
    () async {
      final box = await Hive.openBox(
        'reader_settings_test',
        bytes: Uint8List(0),
      );
      final settings = SettingsController(box);
      expect(settings.preferredBibleTranslation, BibleTranslation.tl1905);
      settings.setLanguage('en');
      expect(settings.preferredBibleTranslation, BibleTranslation.web);
      settings.setPreferredBibleTranslation(BibleTranslation.tl1905);
      settings.setReaderFontSize(99);
      await box.flush();
      final restored = SettingsController(box);
      expect(restored.preferredBibleTranslation, BibleTranslation.tl1905);
      expect(restored.readerFontSize, 30);
      restored.setReaderFontSize(double.nan);
      expect(restored.readerFontSize, 30);
      restored.setReaderFontSize(2);
      expect(restored.readerFontSize, 14);
      settings.dispose();
      restored.dispose();
      await box.close();
    },
  );
}
