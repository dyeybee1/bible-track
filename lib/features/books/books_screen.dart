import 'package:flutter/material.dart';

import '../../data/books_data.dart';
import '../../data/progress_controller.dart';
import '../../models/book.dart';
import '../../settings_scope.dart';
import '../../theme/app_theme.dart';
import '../intro/intro_screen.dart';
import 'chapter_screen.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key, required this.progress});

  final ProgressController progress;

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
      appBar: AppBar(
        title: Text(strings.booksTitle),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const IntroScreen(fromBooks: true),
              ),
            ),
            icon: const Icon(Icons.info_outline, size: 20),
            label: Text(strings.howToUse),
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
                padding: const EdgeInsets.fromLTRB(13, 4, 13, 8),
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings.sectionName(_section),
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      strings.finishedCount(finished, books.length),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  key: ValueKey(_section), // resets scroll when switching tabs
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                          builder: (_) =>
                              ChapterScreen(book: b, progress: widget.progress),
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
          color: selected ? scheme.primary : scheme.surface,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
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
    final teal = doneColor(context);

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
              color: done ? teal : scheme.outlineVariant,
              width: done ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '$read/${book.totalChapters}',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      if (done) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle, color: teal, size: 22),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: read / book.totalChapters,
                      minHeight: 5,
                      backgroundColor: scheme.outlineVariant,
                      color: done ? teal : scheme.primary,
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
