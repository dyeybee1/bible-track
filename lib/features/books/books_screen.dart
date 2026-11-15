import 'package:flutter/material.dart';

import '../../data/account_controller.dart';
import '../../data/books_data.dart';
import '../../data/cloud_repository.dart';
import '../../data/progress_controller.dart';
import '../../data/quiz_repository.dart';
import '../../models/book.dart';
import '../../settings_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../intro/intro_screen.dart';
import 'chapter_screen.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({
    super.key,
    required this.progress,
    required this.account,
    required this.cloud,
    required this.quizRepo,
  });

  final ProgressController progress;
  final AccountController account;
  final CloudRepository cloud;
  final QuizRepository quizRepo;

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  Section _section = Section.oldTestament;

  static const List<Section> _tabOrder = [
    Section.oldTestament,
    Section.newTestament,
    Section.deuterocanonical,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.s;

    return Scaffold(
      appBar: appHeader(
        context,
        title: strings.booksTitle,
        themeToggle: true,
        actions: [
          IconButton(
            tooltip: strings.howToUse,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const IntroScreen(fromBooks: true),
              ),
            ),
            icon: const Icon(Icons.info_outline, size: 20),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.progress,
        builder: (context, _) {
          final books = booksBySection[_section]!;
          final finished = widget.progress.completedIn(books);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 16, 13, 12),
                child: Row(
                  children: [
                    for (final s in _tabOrder)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _SectionTab(
                            label: strings.sectionName(s),
                            selected: s == _section,
                            onTap: () => setState(() => _section = s),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        strings.sectionName(_section),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      strings.finishedCount(finished, books.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  key: ValueKey(_section), // resets scroll when switching tabs
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: books.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final b = books[i];
                    return _BookTile(
                      book: b,
                      name: b.nameFor(strings.lang),
                      read: widget.progress.readCount(b),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChapterScreen(
                            book: b,
                            progress: widget.progress,
                            account: widget.account,
                            cloud: widget.cloud,
                            quizRepo: widget.quizRepo,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? scheme.secondary : scheme.surface,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? scheme.secondary : scheme.outlineVariant,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 6,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? scheme.onSecondary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.book,
    required this.name,
    required this.read,
    required this.onTap,
  });

  final Book book;
  final String name;
  final int read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = read >= book.totalChapters;
    final completed = doneColor(context);

    return Semantics(
      button: true,
      label: context.s.bookSemantics(name, read, book.totalChapters, done),
      child: ExcludeSemantics(
        child: Material(
          color: scheme.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: done ? completed : scheme.outlineVariant,
              width: done ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '$read/${book.totalChapters}',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (done) ...[
                        const SizedBox(width: 8),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: completed,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: onDoneColor(context),
                            size: 20,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: read / book.totalChapters,
                      minHeight: 5,
                      backgroundColor: scheme.outlineVariant,
                      color: done ? completed : scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
