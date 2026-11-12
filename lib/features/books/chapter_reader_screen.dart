import 'package:flutter/material.dart';

import '../../data/bible_text_repository.dart';
import '../../data/progress_controller.dart';
import '../../data/quiz_repository.dart';
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
  late int _chapter = widget.chapter;
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
    _translation = translationForChapter(
      widget.book.id,
      _chapter,
      SettingsScope.of(context).preferredBibleTranslation,
    );
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

  void _changeChapter(int delta) {
    if (_takingQuiz) return;
    setState(() {
      _chapter += delta;
      _loadChapter();
    });
  }

  Future<void> _takeQuiz() async {
    if (_takingQuiz ||
        widget.progress.chaptersRead(widget.book.id).contains(_chapter)) {
      return;
    }
    setState(() => _takingQuiz = true);
    try {
      await showQuiz(
        context: context,
        book: widget.book,
        chapter: _chapter,
        quizRepo: widget.quizRepo,
        progress: widget.progress,
        lang: context.s.lang,
      );
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
    final available = availableTranslations(widget.book.id, _chapter);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.bookChapter(widget.book.nameFor(s.lang), _chapter)),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final t in BibleTranslation.values)
                        ChoiceChip(
                          key: ValueKey('reader-translation-${t.name}'),
                          label: Text(
                            t == BibleTranslation.web
                                ? s.readerEnglish
                                : s.readerTagalog,
                          ),
                          selected: _translation == t,
                          onSelected: available.contains(t) && !_takingQuiz
                              ? (_) => settings.setPreferredBibleTranslation(t)
                              : null,
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: const ValueKey('reader-font-smaller'),
                            tooltip: s.readerSmaller,
                            onPressed: settings.readerFontSize > 14
                                ? () => settings.setReaderFontSize(
                                    settings.readerFontSize - 2,
                                  )
                                : null,
                            icon: const Text('A−'),
                          ),
                          IconButton(
                            key: const ValueKey('reader-font-larger'),
                            tooltip: s.readerLarger,
                            onPressed: settings.readerFontSize < 30
                                ? () => settings.setReaderFontSize(
                                    settings.readerFontSize + 2,
                                  )
                                : null,
                            icon: const Text('A+'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (available.length == 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        s.readerEnglishOnly,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
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
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            pending
                                ? Icons.hourglass_empty
                                : Icons.cloud_off_outlined,
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            pending ? s.readerPending : s.readerError,
                            key: ValueKey(
                              pending
                                  ? 'reader-text-pending'
                                  : 'reader-text-error',
                            ),
                          ),
                          if (!pending)
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
            child: Row(
              children: [
                IconButton(
                  tooltip: s.previousChapter,
                  onPressed: _chapter > 1 && !_takingQuiz
                      ? () => _changeChapter(-1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
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
                IconButton(
                  tooltip: s.nextChapter,
                  onPressed:
                      _chapter < widget.book.totalChapters && !_takingQuiz
                      ? () => _changeChapter(1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
