import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';

import '../../data/bible_text_repository.dart';
import '../../data/progress_controller.dart';
import '../../data/quiz_repository.dart';
import '../../models/book.dart';
import '../../settings_scope.dart';
import '../rank/rank_celebration.dart' show showStarChangeScreen;
import 'chapter_reader_screen.dart';

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
/// [replaceReader] replaces the originating reader instead of retaining it in
/// the stack. Dismissing that quiz restores a reader for the same chapter.
/// Choosing to read after failure replaces the quiz and returns dismissed.
Future<QuizResult> showQuiz({
  required BuildContext context,
  required Book book,
  required int chapter,
  required QuizRepository quizRepo,
  required ProgressController progress,
  required String lang,
  BibleTextRepository? bibleRepo,
  bool replaceReader = false,
}) async {
  final questions = await quizRepo.questionsFor(book.id, chapter);

  if (questions.isEmpty) {
    if (!context.mounted) return QuizResult.dismissed;
    await showStarChangeScreen(
      context: context,
      progress: progress,
      book: book,
      chapter: chapter,
    );
    return QuizResult.passed;
  }

  if (!context.mounted) return QuizResult.dismissed;

  final navigator = Navigator.of(context);
  final textRepo = bibleRepo ?? BibleTextRepository();
  void openReader() {
    navigator.pushReplacement<void, QuizResult>(
      MaterialPageRoute<void>(
        builder: (_) => ChapterReaderScreen(
          book: book,
          chapter: chapter,
          progress: progress,
          quizRepo: quizRepo,
          bibleRepo: textRepo,
        ),
      ),
      result: QuizResult.dismissed,
    );
  }

  final route = MaterialPageRoute<QuizResult>(
    fullscreenDialog: true,
    builder: (_) => _QuizPage(
      book: book,
      chapter: chapter,
      questions: questions,
      progress: progress,
      lang: lang,
      onReadChapter: openReader,
      returnToReader: replaceReader,
    ),
  );
  final result = await (replaceReader
      ? navigator.pushReplacement<QuizResult, void>(route)
      : navigator.push<QuizResult>(route));
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
    required this.onReadChapter,
    required this.returnToReader,
  });

  final Book book;
  final int chapter;
  final List<QuizQuestion> questions;
  final ProgressController progress;
  final String lang;
  final VoidCallback onReadChapter;
  final bool returnToReader;

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
  bool _openingReader = false;

  void _readChapter() {
    if (_openingReader || _markingRead) return;
    _openingReader = true;
    widget.onReadChapter();
  }

  void _close() {
    if (widget.returnToReader) {
      _readChapter();
    } else {
      Navigator.of(context).pop(QuizResult.dismissed);
    }
  }

  Future<void> _markRead() async {
    if (_markingRead) return;
    setState(() => _markingRead = true);
    await showStarChangeScreen(
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
    final canRead =
        chapterTextAvailability(
          widget.book.id,
          widget.chapter,
          translationForLanguage(strings.lang),
        ) ==
        BibleTextAvailability.available;
    final showReadFirst =
        _phase == _QuizPhase.answering &&
        canRead &&
        MediaQuery.viewInsetsOf(context).bottom == 0 &&
        (ModalRoute.isCurrentOf(context) ?? true);
    // Large text needs reserved space for both actions instead of an overlay.
    final readFirstInline =
        showReadFirst && MediaQuery.textScalerOf(context).scale(14) > 21;
    // Reserve the floating action's full height even when its label wraps at
    // large text sizes. The final option can then scroll above the action.
    final actionWidth =
        MediaQuery.sizeOf(context).width -
        MediaQuery.paddingOf(context).horizontal -
        32;
    final labelStyle = theme.textTheme.labelLarge!;
    final labelPainter = TextPainter(
      text: TextSpan(text: strings.quizReadFirst, style: labelStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: (actionWidth - 72).clamp(1, double.infinity));
    final actionHeight = (labelPainter.height + 32).clamp(
      56.0,
      double.infinity,
    );
    labelPainter.dispose();

    return PopScope<QuizResult>(
      canPop: !widget.returnToReader || _markingRead,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        key: const ValueKey('chapter-quiz-screen'),
        appBar: appHeader(
          context,
          showProfileAction: false,
          title: strings.quizTitle(widget.chapter),
          leading: IconButton(
            key: const ValueKey('quiz-close-action'),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            tooltip: strings.chapterClose,
            onPressed: _close,
          ),
        ),
        bottomNavigationBar: _phase == _QuizPhase.answering
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (readFirstInline) ...[
                        OutlinedButton.icon(
                          key: const ValueKey('quiz-read-first-action'),
                          onPressed: _readChapter,
                          icon: const Icon(Icons.menu_book_outlined),
                          label: Text(
                            strings.quizReadFirst,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      FilledButton(
                        key: const ValueKey('quiz-submit-action'),
                        onPressed: _allAnswered ? _submit : null,
                        child: Text(
                          strings.quizCheckAnswers,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _phase == _QuizPhase.wrong
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        key: const ValueKey('quiz-retry-action'),
                        onPressed: _retry,
                        child: Text(
                          strings.quizRetry,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (canRead) ...[
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          key: const ValueKey('quiz-read-chapter-action'),
                          onPressed: _readChapter,
                          icon: const Icon(Icons.menu_book_outlined),
                          label: Text(
                            strings.quizReadChapter,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: showReadFirst && !readFirstInline
            ? ConstrainedBox(
                constraints: BoxConstraints(maxWidth: actionWidth),
                child: FilledButton.tonalIcon(
                  key: const ValueKey('quiz-read-first-action'),
                  onPressed: _readChapter,
                  style: FilledButton.styleFrom(
                    minimumSize: Size(48, actionHeight),
                    backgroundColor: scheme.surface,
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.outlineVariant),
                    padding: const EdgeInsets.all(16),
                    elevation: 2,
                    shadowColor: scheme.shadow.withAlpha(64),
                    shape: const StadiumBorder(),
                    textStyle: labelStyle,
                  ),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(
                    strings.quizReadFirst,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : null,
        body: switch (_phase) {
          _QuizPhase.answering => _AnsweringBody(
            questions: widget.questions,
            selected: _selected,
            lang: widget.lang,
            bottomPadding: showReadFirst && !readFirstInline
                ? actionHeight + 32
                : 8,
            onSelect: (qi, oi) => setState(() => _selected[qi] = oi),
            strings: strings,
            theme: theme,
            scheme: scheme,
          ),
          _QuizPhase.wrong => _ReviewBody(
            questions: widget.questions,
            selected: _selected,
            lang: widget.lang,
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
      ),
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
    required this.bottomPadding,
    required this.onSelect,
    required this.strings,
    required this.theme,
    required this.scheme,
  });

  final List<QuizQuestion> questions;
  final List<int?> selected;
  final String lang;
  final double bottomPadding;
  final void Function(int qi, int oi) onSelect;
  final dynamic strings;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
          child: LinearProgressIndicator(
            value:
                selected.where((value) => value != null).length /
                questions.length,
            minHeight: 4,
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: const ValueKey('quiz-questions'),
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
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
    this.review = false,
  });

  final int index;
  final int total;
  final QuizQuestion question;
  final int? selectedOption;
  final String lang;
  final void Function(int)? onSelect;
  final dynamic strings;
  final ThemeData theme;
  final ColorScheme scheme;
  final bool review;

  @override
  Widget build(BuildContext context) {
    final opts = question.options(lang);
    final correct = selectedOption == question.answer;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'Newsreader',
                fontSize: 21,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Options
            for (var oi = 0; oi < opts.length; oi++)
              _OptionTile(
                label: opts[oi],
                selected: selectedOption == oi,
                onTap: onSelect == null ? null : () => onSelect!(oi),
                scheme: scheme,
                theme: theme,
                wrong: review && selectedOption == oi && !correct,
                semanticFeedback: !review
                    ? null
                    : selectedOption == oi
                    ? (correct
                          ? context.s.quizYourAnswerCorrect
                          : context.s.quizYourAnswerWrong)
                    : !correct && oi == question.answer
                    ? context.s.quizCorrectAnswer
                    : null,
              ),
            if (review && !correct) ...[
              const SizedBox(height: 4),
              Text(
                question.explanation(lang),
                style: theme.textTheme.bodyMedium,
              ),
            ],
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
    this.semanticFeedback,
    this.wrong = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final ColorScheme scheme;
  final ThemeData theme;
  final String? semanticFeedback;
  final bool wrong;

  @override
  Widget build(BuildContext context) {
    final reviewing = onTap == null;
    final highlighted = reviewing ? semanticFeedback != null : selected;
    final foreground = highlighted
        ? (wrong ? scheme.onErrorContainer : scheme.onPrimaryContainer)
        : scheme.onSurface;
    final decoration = BoxDecoration(
      color: highlighted
          ? (wrong ? scheme.errorContainer : scheme.primaryContainer)
          : scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: highlighted
            ? (wrong ? scheme.error : scheme.primary).withValues(alpha: .25)
            : Colors.transparent,
        width: 1,
      ),
    );
    final content = Row(
      children: [
        Icon(
          semanticFeedback != null
              ? (wrong ? Icons.close_rounded : Icons.check_rounded)
              : selected && !reviewing
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          size: 18,
          color: highlighted ? foreground : scheme.outline,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: foreground,
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
    if (reviewing) {
      return Semantics(
        container: true,
        label: [label, ?semanticFeedback].join(', '),
        child: ExcludeSemantics(
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: decoration,
            child: content,
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 48),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: decoration,
        child: content,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 2 – Wrong answers
// ─────────────────────────────────────────────────────────────────────────────

/// Read-only feedback using the same question and option layout as the quiz.
class QuizReviewCard extends StatelessWidget {
  const QuizReviewCard({
    super.key,
    required this.index,
    required this.total,
    required this.question,
    required this.selectedOption,
    required this.lang,
  });

  final int index;
  final int total;
  final QuizQuestion question;
  final int selectedOption;
  final String lang;

  @override
  Widget build(BuildContext context) => _QuestionCard(
    index: index,
    total: total,
    question: question,
    selectedOption: selectedOption,
    lang: lang,
    onSelect: null,
    strings: context.s,
    theme: Theme.of(context),
    scheme: Theme.of(context).colorScheme,
    review: true,
  );
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.questions,
    required this.selected,
    required this.lang,
  });

  final List<QuizQuestion> questions;
  final List<int?> selected;
  final String lang;

  @override
  Widget build(BuildContext context) => ListView.builder(
    key: const ValueKey('quiz-review'),
    // Each review starts at the top, independently of the answering list.
    primary: false,
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
    itemCount: questions.length + 1,
    itemBuilder: (context, i) => i == 0
        ? Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              context.s.quizReviewTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          )
        : QuizReviewCard(
            key: ValueKey('quiz-review-card-${i - 1}'),
            index: i - 1,
            total: questions.length,
            question: questions[i - 1],
            selectedOption: selected[i - 1]!,
            lang: lang,
          ),
  );
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
                  color: scheme.surface,
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [scheme.primaryContainer, scheme.surface],
                  ),
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_florist_rounded,
                        size: 36,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.quizPassed as String,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurface,
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
                    color: scheme.surface,
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
