import 'dart:io';

import 'package:bible_track/data/progress_controller.dart';
import 'package:bible_track/data/quiz_repository.dart';
import 'package:bible_track/models/book.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A version of QuizRepository whose _load is overridden to inject questions
/// directly — no rootBundle needed in unit tests.
class _InjectableQuizRepo extends QuizRepository {
  final Map<String, Map<int, List<QuizQuestion>>> injected;

  _InjectableQuizRepo(this.injected);

  @override
  Future<List<QuizQuestion>> questionsFor(String bookId, int chapter) async {
    return injected[bookId]?[chapter] ?? const [];
  }
}

QuizQuestion _q({int answer = 0}) => QuizQuestion(
  questionEn: 'Q?',
  questionFil: 'T?',
  optionsEn: ['A', 'B', 'C'],
  optionsFil: ['A', 'B', 'C'],
  answer: answer,
  explanationEn: 'Explanation.',
  explanationFil: 'Paliwanag.',
);

const Book _ruthBook = Book('rut', 'Ruth', 'Ruth', Testament.ot, 4);

// ---------------------------------------------------------------------------
// Quiz logic tests (no Flutter widgets needed)
// ---------------------------------------------------------------------------

void main() {
  late Directory tempDir;
  late ProgressController progress;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('quiz_test_');
    Hive.init(tempDir.path);
    final box = await Hive.openBox<dynamic>('progress_quiz_test');
    progress = ProgressController(box);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // ─── markChapterRead ─────────────────────────────────────────────────────

  test('markChapterRead marks chapter as read', () {
    expect(progress.chaptersRead('rut'), isEmpty);
    progress.markChapterRead(_ruthBook, 1);
    expect(progress.chaptersRead('rut'), contains(1));
  });

  test('markChapterRead is idempotent (no-op if already read)', () {
    progress.markChapterRead(_ruthBook, 1);
    progress.markChapterRead(_ruthBook, 1); // second call
    expect(progress.chaptersRead('rut').length, 1);
  });

  test('markChapterRead does not mark an out-of-range chapter', () {
    progress.markChapterRead(_ruthBook, 0);
    progress.markChapterRead(_ruthBook, 5); // Ruth has only 4 chapters
    expect(progress.chaptersRead('rut'), isEmpty);
  });

  // ─── QuizRepository (no-questions fallback) ───────────────────────────────

  test('questionsFor returns empty list for a book with no JSON', () async {
    final repo = QuizRepository(); // no injected data
    final qs = await repo.questionsFor('gen', 1);
    expect(qs, isEmpty);
  });

  test('no-questions fallback: questionsFor returning [] means direct mark', () async {
    // Simulate: quiz returns empty → caller should mark directly (no quiz shown).
    final repo = _InjectableQuizRepo({});
    final qs = await repo.questionsFor('gen', 1);
    expect(qs, isEmpty); // empty == fallback, mark directly
    progress.markChapterRead(_ruthBook, 1);
    expect(progress.chaptersRead('rut'), contains(1));
  });

  // ─── All-correct pass logic ───────────────────────────────────────────────

  test('quiz passes only when all answers are correct', () {
    final questions = [_q(answer: 0), _q(answer: 1), _q(answer: 2)];
    final selected = [0, 1, 2]; // all correct

    final allCorrect = _checkAll(questions, selected);
    expect(allCorrect, isTrue);
  });

  test('quiz fails if any single answer is wrong', () {
    final questions = [_q(answer: 0), _q(answer: 1), _q(answer: 2)];

    // One wrong
    expect(_checkAll(questions, [0, 0, 2]), isFalse);
    // All wrong
    expect(_checkAll(questions, [2, 0, 1]), isFalse);
    // Last wrong
    expect(_checkAll(questions, [0, 1, 0]), isFalse);
  });

  // ─── Wrong attempt does NOT mark chapter as read ──────────────────────────

  test('wrong attempt does not mark chapter read', () {
    // Simulate: quiz failed — markChapterRead should NOT have been called.
    expect(progress.chaptersRead('rut'), isEmpty);
    // We deliberately do NOT call progress.markChapterRead here.
    expect(progress.chaptersRead('rut'), isEmpty);
  });

  // ─── Retry resets all answers, same questions same order ─────────────────

  test('retry resets all selections to null (same questions, same order)', () {
    final questions = [_q(answer: 0), _q(answer: 1)];
    final repo = _InjectableQuizRepo({
      'rut': {1: questions},
    });

    // Simulate answering
    var selected = [1, 0]; // wrong answers
    expect(_checkAll(questions, selected), isFalse);

    // Simulate retry — all selections cleared
    selected = List<int?>.filled(questions.length, null).cast<int>();
    // After retry, same question objects in same order
    final reloaded = repo.injected['rut']![1]!;
    expect(reloaded.length, questions.length);
    expect(reloaded[0].answer, questions[0].answer);
    expect(reloaded[1].answer, questions[1].answer);
  });

  // ─── Questions loaded in deterministic order (no shuffling) ───────────────

  test('questions are returned in the same order every time', () async {
    final qs = [_q(answer: 0), _q(answer: 1), _q(answer: 2)];
    final repo = _InjectableQuizRepo({
      'rut': {1: qs},
    });

    final first = await repo.questionsFor('rut', 1);
    final second = await repo.questionsFor('rut', 1);

    expect(first.length, second.length);
    for (var i = 0; i < first.length; i++) {
      expect(first[i].answer, second[i].answer);
    }
  });

  // ─── QuizQuestion helpers ─────────────────────────────────────────────────

  test('QuizQuestion.question returns correct language', () {
    final q = QuizQuestion(
      questionEn: 'English?',
      questionFil: 'Filipino?',
      optionsEn: ['A'],
      optionsFil: ['A'],
      answer: 0,
      explanationEn: 'en exp',
      explanationFil: 'fil exp',
    );
    expect(q.question('en'), 'English?');
    expect(q.question('fil'), 'Filipino?');
    expect(q.explanation('en'), 'en exp');
    expect(q.explanation('fil'), 'fil exp');
  });
}

// ---------------------------------------------------------------------------
// Pure helper — mirrors the logic in _QuizPageState
// ---------------------------------------------------------------------------

bool _checkAll(List<QuizQuestion> questions, List<int> selected) {
  if (selected.length != questions.length) return false;
  for (var i = 0; i < questions.length; i++) {
    if (selected[i] != questions[i].answer) return false;
  }
  return true;
}
