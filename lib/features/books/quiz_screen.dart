import 'package:flutter/material.dart';

import '../../data/progress_controller.dart';
import '../../data/quiz_repository.dart';
import '../../models/book.dart';
import '../../settings_scope.dart';
import '../rank/rank_celebration.dart';

/// Result returned when the quiz dialog closes.
enum QuizResult {
  /// User passed all questions — chapter should be marked read.
  passed,

  /// User dismissed without passing (back button / gave up).
  dismissed,
}

/// Opens a full-screen quiz for [book] chapter [chapter].
///
/// Returns [QuizResult.passed] when all questions are answered correctly and
/// the user taps "Mark as read". Returns [QuizResult.dismissed] otherwise.
///
/// If the book/chapter has no questions, marks it directly and returns passed.
Future<QuizResult> showQuiz({
  required BuildContext context,
  required Book book,
  required int chapter,
  required QuizRepository quizRepo,
  required ProgressController progress,
  required String lang,
}) async {
  final questions = await quizRepo.questionsFor(book.id, chapter);

  if (questions.isEmpty) {
    if (!context.mounted) return QuizResult.dismissed;
    await markChapterReadWithRankUp(
      context: context,
      progress: progress,
      book: book,
      chapter: chapter,
    );
    return QuizResult.passed;
  }

  if (!context.mounted) return QuizResult.dismissed;

  final result = await Navigator.of(context).push<QuizResult>(
    MaterialPageRoute<QuizResult>(
      fullscreenDialog: true,
      builder: (_) => _QuizPage(
        book: book,
        chapter: chapter,
        questions: questions,
        progress: progress,
        lang: lang,
      ),
    ),
  );
  return result ?? QuizResult.dismissed;
}

// ─────────────────────────────────────────────────────────────────────────────

enum _QuizPhase { answering, wrong, passed }

class _QuizPage extends StatefulWidget {
  const _QuizPage({
    required this.book,
    required this.chapter,
    required this.questions,
    required this.progress,
    required this.lang,
  });

  final Book book;
  final int chapter;
  final List<QuizQuestion> questions;
  final ProgressController progress;
  final String lang;

  @override
  State<_QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<_QuizPage> {
  // Selected option index per question (null = not answered yet).
  late List<int?> _selected;
  _QuizPhase _phase = _QuizPhase.answering;

  @override
  void initState() {
    super.initState();
    _resetAnswers();
  }

  void _resetAnswers() {
    _selected = List<int?>.filled(widget.questions.length, null);
  }

  bool get _allAnswered => _selected.every((s) => s != null);

  bool get _allCorrect {
    for (var i = 0; i < widget.questions.length; i++) {
      if (_selected[i] != widget.questions[i].answer) return false;
    }
    return true;
  }

  void _submit() {
    if (!_allAnswered) return;
    setState(() {
      _phase = _allCorrect ? _QuizPhase.passed : _QuizPhase.wrong;
    });
  }

  void _retry() {
    setState(() {
      _resetAnswers();
      _phase = _QuizPhase.answering;
    });
  }

  bool _markingRead = false;

  Future<void> _markRead() async {
    if (_markingRead) return;
    _markingRead = true;
    await markChapterReadWithRankUp(
      context: context,
      progress: widget.progress,
      book: widget.book,
      chapter: widget.chapter,
    );
    if (mounted) Navigator.of(context).pop(QuizResult.passed);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.quizTitle(widget.chapter)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(QuizResult.dismissed),
        ),
      ),
      body: switch (_phase) {
        _QuizPhase.answering => _AnsweringBody(
          questions: widget.questions,
          selected: _selected,
          lang: widget.lang,
          allAnswered: _allAnswered,
          onSelect: (qi, oi) => setState(() => _selected[qi] = oi),
          onSubmit: _submit,
          strings: strings,
          theme: theme,
          scheme: scheme,
        ),
        _QuizPhase.wrong => _WrongBody(
          strings: strings,
          theme: theme,
          scheme: scheme,
          onRetry: _retry,
        ),
        _QuizPhase.passed => _PassedBody(
          questions: widget.questions,
          lang: widget.lang,
          strings: strings,
          theme: theme,
          scheme: scheme,
          onMarkRead: _markRead,
        ),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 1 – Answering
// ─────────────────────────────────────────────────────────────────────────────

class _AnsweringBody extends StatelessWidget {
  const _AnsweringBody({
    required this.questions,
    required this.selected,
    required this.lang,
    required this.allAnswered,
    required this.onSelect,
    required this.onSubmit,
    required this.strings,
    required this.theme,
    required this.scheme,
  });

  final List<QuizQuestion> questions;
  final List<int?> selected;
  final String lang;
  final bool allAnswered;
  final void Function(int qi, int oi) onSelect;
  final VoidCallback onSubmit;
  final dynamic strings;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: questions.length,
            itemBuilder: (_, qi) => _QuestionCard(
              index: qi,
              total: questions.length,
              question: questions[qi],
              selectedOption: selected[qi],
              lang: lang,
              onSelect: (oi) => onSelect(qi, oi),
              strings: strings,
              theme: theme,
              scheme: scheme,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: allAnswered ? onSubmit : null,
                child: Text(strings.quizCheckAnswers as String),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.total,
    required this.question,
    required this.selectedOption,
    required this.lang,
    required this.onSelect,
    required this.strings,
    required this.theme,
    required this.scheme,
  });

  final int index;
  final int total;
  final QuizQuestion question;
  final int? selectedOption;
  final String lang;
  final void Function(int) onSelect;
  final dynamic strings;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final opts = question.options(lang);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number + progress
            Text(
              strings.quizProgress(index + 1, total) as String,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              question.question(lang),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Options
            for (var oi = 0; oi < opts.length; oi++)
              _OptionTile(
                label: opts[oi],
                selected: selectedOption == oi,
                onTap: () => onSelect(oi),
                scheme: scheme,
                theme: theme,
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
    required this.theme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 2 – Wrong answers
// ─────────────────────────────────────────────────────────────────────────────

class _WrongBody extends StatelessWidget {
  const _WrongBody({
    required this.strings,
    required this.theme,
    required this.scheme,
    required this.onRetry,
  });

  final dynamic strings;
  final ThemeData theme;
  final ColorScheme scheme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh_rounded,
              size: 72,
              color: scheme.primary.withAlpha(180),
            ),
            const SizedBox(height: 20),
            Text(
              strings.quizWrong as String,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.replay),
              label: Text(strings.quizRetry as String),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 3 – Passed: celebration + explanations
// ─────────────────────────────────────────────────────────────────────────────

class _PassedBody extends StatelessWidget {
  const _PassedBody({
    required this.questions,
    required this.lang,
    required this.strings,
    required this.theme,
    required this.scheme,
    required this.onMarkRead,
  });

  final List<QuizQuestion> questions;
  final String lang;
  final dynamic strings;
  final ThemeData theme;
  final ColorScheme scheme;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            children: [
              // Celebration banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    Text(
                      strings.quizPassed as String,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Explanations
              Text(
                strings.quizLearnedTitle as String,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              for (final q in questions)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.question(lang),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        q.explanation(lang),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Mark as read button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onMarkRead,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(strings.quizMarkRead as String),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
