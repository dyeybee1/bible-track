import 'dart:convert';

import 'package:flutter/services.dart';

/// One question in a quiz.
class QuizQuestion {
  const QuizQuestion({
    required this.questionEn,
    required this.questionFil,
    required this.optionsEn,
    required this.optionsFil,
    required this.answer,
    required this.explanationEn,
    required this.explanationFil,
  });

  final String questionEn;
  final String questionFil;
  final List<String> optionsEn;
  final List<String> optionsFil;

  /// 0-based index of the correct option.
  final int answer;

  final String explanationEn;
  final String explanationFil;

  String question(String lang) => lang == 'fil' ? questionFil : questionEn;
  List<String> options(String lang) =>
      lang == 'fil' ? optionsFil : optionsEn;
  String explanation(String lang) =>
      lang == 'fil' ? explanationFil : explanationEn;

  factory QuizQuestion.fromMap(Map<String, dynamic> m) {
    final q = m['q'] as Map<String, dynamic>;
    final opts = m['options'] as Map<String, dynamic>;
    final exp = m['explanation'] as Map<String, dynamic>;
    return QuizQuestion(
      questionEn: q['en'] as String,
      questionFil: q['fil'] as String,
      optionsEn: List<String>.from(opts['en'] as List),
      optionsFil: List<String>.from(opts['fil'] as List),
      answer: (m['answer'] as num).toInt(),
      explanationEn: exp['en'] as String,
      explanationFil: exp['fil'] as String,
    );
  }
}

/// Loads quiz questions from bundled JSON assets.
///
/// Asset path: assets/questions/{bookId}.json
///
/// JSON schema:
/// ```json
/// {
///   "chapters": {
///     "1": [ { "q": {"en":"...","fil":"..."}, "options": {...},
///              "answer": 0, "explanation": {"en":"...","fil":"..."} }, … ],
///     "2": [ … ]
///   }
/// }
/// ```
///
/// Questions and options are returned in the EXACT order stored in the file —
/// no shuffling ever happens.
class QuizRepository {
  /// In-memory cache: bookId → chapter → questions.
  final Map<String, Map<int, List<QuizQuestion>>> _cache = {};

  /// Returns the questions for [bookId] chapter [chapter], or an empty list
  /// if no questions are defined. Never throws; returns [] on any error.
  Future<List<QuizQuestion>> questionsFor(String bookId, int chapter) async {
    if (!_cache.containsKey(bookId)) {
      await _load(bookId);
    }
    return _cache[bookId]?[chapter] ?? const [];
  }

  Future<void> _load(String bookId) async {
    _cache[bookId] = {};
    try {
      final raw = await rootBundle.loadString(
        'assets/questions/$bookId.json',
      );
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final chapters = json['chapters'] as Map<String, dynamic>;
      for (final entry in chapters.entries) {
        final ch = int.tryParse(entry.key);
        if (ch == null) continue;
        final list = entry.value as List<dynamic>;
        _cache[bookId]![ch] = list
            .whereType<Map<String, dynamic>>()
            .map(QuizQuestion.fromMap)
            .toList();
      }
    } catch (_) {
      // File absent or malformed → empty (no-quiz fallback).
    }
  }
}
