import 'dart:convert';

import 'package:flutter/services.dart';

import 'bible_translation.dart';
export 'bible_translation.dart';

class Verse {
  const Verse({required this.number, required this.text});
  final int number;
  final String text;
}

/// An intentional editorial state, separate from an asset/network failure.
class BibleTextPendingException implements Exception {
  const BibleTextPendingException(this.bookId, this.chapter);
  final String bookId;
  final int chapter;
}

/// This chapter has no text in the requested language. Never substitutes text.
class BibleTextUnavailableException implements Exception {
  const BibleTextUnavailableException(
    this.bookId,
    this.chapter,
    this.translation,
  );
  final String bookId;
  final int chapter;
  final BibleTranslation translation;
}

/// Loads one source-numbered book at a time, then applies the reviewed mapping
/// exactly once. No progress, account, network or cloud dependencies.
class BibleTextRepository {
  BibleTextRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final _books = <String, Future<Map<String, dynamic>>>{};
  Future<Map<String, dynamic>>? _mapping;

  Future<Map<String, dynamic>> _read(String path) async =>
      jsonDecode(await _bundle.loadString(path, cache: false))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> _loadMapping() async {
    final pending = _mapping ??= _read('assets/bible/mapping.json');
    try {
      return await pending;
    } catch (_) {
      if (identical(_mapping, pending)) _mapping = null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _loadBook(
    BibleTranslation translation,
    String bookId,
  ) async {
    final key = '${translation.name}/$bookId';
    final pending = _books.putIfAbsent(
      key,
      () => _read('assets/bible/$key.json'),
    );
    try {
      final book = await pending;
      if (book['book'] != bookId) {
        throw const FormatException('Wrong Bible book');
      }
      return book;
    } catch (_) {
      if (identical(_books[key], pending)) _books.remove(key);
      rethrow;
    }
  }

  Future<List<Verse>> loadChapter(
    String bookId,
    int chapter,
    BibleTranslation translation,
  ) async {
    final availability = chapterTextAvailability(bookId, chapter, translation);
    if (availability == BibleTextAvailability.unavailable) {
      throw BibleTextUnavailableException(bookId, chapter, translation);
    }
    if (availability == BibleTextAvailability.pending) {
      throw BibleTextPendingException(bookId, chapter);
    }
    final mapping = await _loadMapping();
    final translations = mapping['translations'] as Map;
    final rules = (translations[translation.name] as Map)['books'] as Map;
    final rule = rules[bookId] as Map?;
    if (rule != null && (rule['pending_chapters'] as List).contains(chapter)) {
      throw BibleTextPendingException(bookId, chapter);
    }
    final segments = rule == null
        ? null
        : (rule['chapters'] as Map)['$chapter'] as List?;
    if (rule != null && segments == null) {
      throw const FormatException('Missing Bible chapter mapping');
    }
    final result = <Verse>[];
    if (segments == null) {
      final book = await _loadBook(translation, bookId);
      final raw = (book['chapters'] as Map)['$chapter'] as List;
      result.addAll(
        raw.map((v) => Verse(number: v['v'] as int, text: v['t'] as String)),
      );
    } else {
      for (final segment in segments.cast<Map>()) {
        final sourceBook = segment['source_book'] as String;
        if (sourceBook != bookId) {
          throw const FormatException('Unexpected cross-book Bible mapping');
        }
        final book = await _loadBook(translation, sourceBook);
        final raw =
            (book['chapters'] as Map)['${segment['source_chapter']}'] as List;
        final range = (segment['source_verses'] as List).cast<int>();
        final selected = raw
            .cast<Map>()
            .where(
              (v) => (v['v'] as int) >= range[0] && (v['v'] as int) <= range[1],
            )
            .toList();
        if (selected.isEmpty ||
            selected.first['v'] != range[0] ||
            selected.last['v'] != range[1]) {
          throw const FormatException('Bible mapping endpoint missing');
        }
        for (final verse in selected) {
          var text = verse['t'] as String;
          if (segment.containsKey('text_start') ||
              segment.containsKey('text_end')) {
            if (range[0] != range[1]) {
              throw const FormatException('Invalid Bible span');
            }
            int anchor(String key, int fallback) {
              final value = segment[key] as String?;
              if (value == null) return fallback;
              final index = text.indexOf(value);
              if (index < 0 || text.indexOf(value, index + 1) >= 0) {
                throw const FormatException('Bible text boundary needs review');
              }
              return index;
            }

            final start = anchor('text_start', 0);
            final end = anchor('text_end', text.length);
            if (start >= end) {
              throw const FormatException('Reversed Bible span');
            }
            text = text.substring(start, end).trim();
          }
          result.add(
            Verse(
              number:
                  (segment['app_verse_start'] as int) +
                  (verse['v'] as int) -
                  range[0],
              text: text,
            ),
          );
        }
      }
    }
    if (result.isEmpty ||
        result.first.number != 1 ||
        result.any((v) => v.text.trim().isEmpty) ||
        result.map((v) => v.number).toSet().length != result.length) {
      throw const FormatException('Empty or invalid Bible chapter');
    }
    return List.unmodifiable(result);
  }
}
