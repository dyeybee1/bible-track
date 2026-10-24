import 'package:flutter/material.dart';

import '../../data/progress_controller.dart';
import '../../models/book.dart';
import '../../settings_scope.dart';
import '../../theme/app_theme.dart';

class ChapterScreen extends StatefulWidget {
  const ChapterScreen({super.key, required this.book, required this.progress});

  final Book book;
  final ProgressController progress;

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  /// One-shot mode: the next tapped chapter marks everything up to it.
  bool _upTo = false;

  Future<void> _confirmClear() async {
    final strings = context.s;
    final name = widget.book.nameFor(strings.lang);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.clearTitle),
        content: Text(strings.clearBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.clearConfirm),
          ),
        ],
      ),
    );
    if (ok == true) widget.progress.clearBook(widget.book);
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final strings = context.s;
    final name = book.nameFor(strings.lang);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final teal = doneColor(context);

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListenableBuilder(
        listenable: widget.progress,
        builder: (context, _) {
          final read = widget.progress.chaptersRead(book.id);
          final count = read.length;
          final done = count >= book.totalChapters;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.chaptersCount(count, book.totalChapters),
                          style: theme.textTheme.titleMedium,
                        ),
                        if (done)
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: teal, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                strings.finishedLabel,
                                style: TextStyle(
                                  color: teal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: count / book.totalChapters,
                        minHeight: 6,
                        backgroundColor: scheme.outlineVariant,
                        color: done ? teal : scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: done
                    ? Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: teal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          strings.finishedBookMessage(name),
                          style: TextStyle(
                            color: onDoneColor(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(strings.markUpTo),
                      selected: _upTo,
                      onSelected: (v) => setState(() => _upTo = v),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: Text(strings.markAll),
                      onPressed: done
                          ? null
                          : () => widget.progress.markAll(book),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: Text(strings.clearAll),
                      onPressed: count == 0 ? null : _confirmClear,
                    ),
                  ],
                ),
              ),
              if (_upTo)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    strings.upToHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 64,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: book.totalChapters,
                  itemBuilder: (context, i) {
                    final chapter = i + 1;
                    return _ChapterCell(
                      number: chapter,
                      read: read.contains(chapter),
                      onTap: () {
                        if (_upTo) {
                          widget.progress.markUpTo(book, chapter);
                          setState(() => _upTo = false);
                        } else {
                          widget.progress.toggleChapter(book, chapter);
                        }
                      },
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

class _ChapterCell extends StatelessWidget {
  const _ChapterCell({
    required this.number,
    required this.read,
    required this.onTap,
  });

  final int number;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final teal = doneColor(context);

    return Semantics(
      button: true,
      label: context.s.chapterSemantics(number, read),
      child: ExcludeSemantics(
        child: Material(
          color: read ? teal : scheme.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: read ? teal : scheme.outlineVariant),
          ),
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: read ? onDoneColor(context) : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
