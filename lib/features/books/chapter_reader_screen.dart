import 'package:flutter/material.dart';

import '../../data/bible_text_repository.dart';
import '../../data/progress_controller.dart';
import '../../data/quiz_repository.dart';
import '../../data/settings_controller.dart';
import '../../models/book.dart';
import '../../settings_scope.dart';
import '../settings/text_sources_screen.dart';
import 'quiz_screen.dart';

class ChapterReaderScreen extends StatefulWidget {
  const ChapterReaderScreen({
    super.key,
    required this.book,
    required this.chapter,
    required this.progress,
    required this.quizRepo,
    required this.bibleRepo,
  });

  final Book book;
  final int chapter;
  final ProgressController progress;
  final QuizRepository quizRepo;
  final BibleTextRepository bibleRepo;

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  final _scroll = ScrollController();
  int get _chapter => widget.chapter;
  late BibleTranslation _translation;
  Future<List<Verse>>? _text;
  Future<List<QuizQuestion>>? _questions;
  String? _textKey;
  int? _questionsChapter;
  bool _takingQuiz = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadChapter();
  }

  void _loadChapter() {
    _translation = translationForLanguage(SettingsScope.of(context).language);
    final key = '$_chapter/${_translation.name}';
    if (_textKey != key) {
      _textKey = key;
      _text = widget.bibleRepo.loadChapter(
        widget.book.id,
        _chapter,
        _translation,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    }
    if (_questionsChapter != _chapter) {
      _questionsChapter = _chapter;
      _questions = widget.quizRepo.questionsFor(widget.book.id, _chapter);
    }
  }

  Future<void> _takeQuiz() async {
    if (_takingQuiz ||
        widget.progress.chaptersRead(widget.book.id).contains(_chapter)) {
      return;
    }
    setState(() => _takingQuiz = true);
    try {
      final navigator = Navigator.of(context);
      final readerRoute = ModalRoute.of(context)!;
      final result = await showQuiz(
        context: context,
        book: widget.book,
        chapter: _chapter,
        quizRepo: widget.quizRepo,
        progress: widget.progress,
        lang: context.s.lang,
        bibleRepo: widget.bibleRepo,
        replaceReader: true,
      );
      if (mounted && result == QuizResult.passed) {
        // No-question chapters mark directly without replacing this reader.
        if (readerRoute.isCurrent) {
          navigator.pop();
        } else {
          navigator.removeRoute(readerRoute);
        }
      }
    } finally {
      if (mounted) setState(() => _takingQuiz = false);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = SettingsScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.bookChapter(widget.book.nameFor(s.lang), _chapter)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const ValueKey('reader-font-smaller'),
                      tooltip: s.readerSmaller,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: settings.readerFontSizeIndex > 0
                          ? () => settings.setReaderFontSize(
                              SettingsController.readerFontSizes[settings
                                      .readerFontSizeIndex -
                                  1],
                            )
                          : null,
                      icon: const Icon(Icons.text_decrease),
                    ),
                    SizedBox(
                      height: 24,
                      child: VerticalDivider(
                        width: 1,
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('reader-font-larger'),
                      tooltip: s.readerLarger,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed:
                          settings.readerFontSizeIndex <
                              SettingsController.readerFontSizes.length - 1
                          ? () => settings.setReaderFontSize(
                              SettingsController.readerFontSizes[settings
                                      .readerFontSizeIndex +
                                  1],
                            )
                          : null,
                      icon: const Icon(Icons.text_increase),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<Verse>>(
                future: _text,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(s.readerLoading),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    final pending = snapshot.error is BibleTextPendingException;
                    final unavailable =
                        snapshot.error is BibleTextUnavailableException;
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              unavailable
                                  ? Icons.menu_book_outlined
                                  : pending
                                  ? Icons.hourglass_empty
                                  : Icons.cloud_off_outlined,
                              size: 36,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              unavailable
                                  ? s.readerTagalogUnavailable
                                  : pending
                                  ? s.readerPending
                                  : s.readerError,
                              textAlign: TextAlign.center,
                              key: ValueKey(
                                unavailable
                                    ? 'reader-text-unavailable'
                                    : pending
                                    ? 'reader-text-pending'
                                    : 'reader-text-error',
                              ),
                            ),
                            if (unavailable) ...[
                              const SizedBox(height: 8),
                              Text(
                                s.readerChangeLanguageHint,
                                textAlign: TextAlign.center,
                              ),
                            ],
                            if (!pending && !unavailable)
                              OutlinedButton(
                                onPressed: () => setState(() {
                                  _text = widget.bibleRepo.loadChapter(
                                    widget.book.id,
                                    _chapter,
                                    _translation,
                                  );
                                }),
                                child: Text(s.readerRetry),
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                  final verses = snapshot.requireData;
                  return ListView.builder(
                    key: const ValueKey('reader-verses'),
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: verses.length,
                    itemBuilder: (context, index) {
                      final verse = verses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text.rich(
                          key: ValueKey('reader-verse-${verse.number}'),
                          TextSpan(
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.top,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: 5,
                                    top: 3,
                                  ),
                                  child: Text(
                                    '${verse.number}',
                                    style: TextStyle(
                                      fontSize: settings.readerFontSize * .6,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              TextSpan(text: verse.text),
                            ],
                          ),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: settings.readerFontSize,
                            height: 1.65,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const TextSourcesScreen()),
              ),
              child: Text(
                s.readerCredit(_translation == BibleTranslation.web),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Material(
        color: theme.colorScheme.surface,
        elevation: 4,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ListenableBuilder(
                listenable: widget.progress,
                builder: (context, _) => FutureBuilder<List<QuizQuestion>>(
                  future: _questions,
                  builder: (context, snapshot) {
                    final read = widget.progress
                        .chaptersRead(widget.book.id)
                        .contains(_chapter);
                    final ready =
                        snapshot.connectionState == ConnectionState.done;
                    return FilledButton(
                      key: const ValueKey('reader-quiz-action'),
                      onPressed: read || _takingQuiz || !ready
                          ? null
                          : _takeQuiz,
                      child: Text(
                        read
                            ? s.readerAlreadyRead
                            : !ready
                            ? s.readerLoading
                            : (snapshot.data?.isEmpty ?? true)
                            ? s.chapterMarkRead
                            : s.readerQuiz,
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
