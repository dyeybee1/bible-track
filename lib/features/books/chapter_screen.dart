import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/account_controller.dart';
import '../../data/cloud_repository.dart';
import '../../data/progress_controller.dart';
import '../../models/book.dart';
import '../../settings_scope.dart';
import '../../theme/app_theme.dart';

class ChapterScreen extends StatefulWidget {
  const ChapterScreen({
    super.key,
    required this.book,
    required this.progress,
    required this.account,
    required this.cloud,
  });

  final Book book;
  final ProgressController progress;
  final AccountController account;
  final CloudRepository cloud;

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

  void _showFinishersSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FinishersSheet(
        book: widget.book,
        cloud: widget.cloud,
        currentUid: widget.account.user?.uid,
      ),
    );
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

              // ── "Mga Nakatapos" inline preview ───────────────────────────
              _FinishersPreview(
                book: book,
                cloud: widget.cloud,
                currentUid: widget.account.user?.uid,
                onSeeAll: _showFinishersSheet,
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

// ─────────────────────────────────────────────────────────────────────────────
// Inline preview strip shown between the chips and the chapter grid.
// Shows "N nakatapos" button (or loading/offline/empty). Tapping opens sheet.
// ─────────────────────────────────────────────────────────────────────────────

enum _FinishersStatus { loading, loaded, offline }

class _FinishersPreview extends StatefulWidget {
  const _FinishersPreview({
    required this.book,
    required this.cloud,
    required this.currentUid,
    required this.onSeeAll,
  });

  final Book book;
  final CloudRepository cloud;
  final String? currentUid;
  final VoidCallback onSeeAll;

  @override
  State<_FinishersPreview> createState() => _FinishersPreviewState();
}

class _FinishersPreviewState extends State<_FinishersPreview> {
  _FinishersStatus _status = _FinishersStatus.loading;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _status = _FinishersStatus.loading);
    final result = await widget.cloud.fetchBookFinishers(
      widget.book.id,
      limit: 50,
    );
    if (!mounted) return;
    setState(() {
      if (result == null) {
        _status = _FinishersStatus.offline;
      } else {
        _rows = result;
        _status = _FinishersStatus.loaded;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_status == _FinishersStatus.loading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
        child: Row(
          children: [
            Icon(Icons.people_outline, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              strings.finishersLoading,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (_status == _FinishersStatus.offline) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              strings.finishersOffline,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Loaded state
    if (_rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
        child: Row(
          children: [
            Icon(Icons.people_outline, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              strings.finishersEmpty,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Show count badge + tap to open full sheet
    final count = _rows.length;
    final iAmThere = _rows.any((r) => r['uid'] == widget.currentUid);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: InkWell(
        onTap: widget.onSeeAll,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                strings.finishersCount(count),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (iAmThere) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    strings.finishersYou,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Icon(Icons.chevron_right, size: 16, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full bottom-sheet with scrollable list of who finished the book.
// ─────────────────────────────────────────────────────────────────────────────

class _FinishersSheet extends StatefulWidget {
  const _FinishersSheet({
    required this.book,
    required this.cloud,
    required this.currentUid,
  });

  final Book book;
  final CloudRepository cloud;
  final String? currentUid;

  @override
  State<_FinishersSheet> createState() => _FinishersSheetState();
}

class _FinishersSheetState extends State<_FinishersSheet> {
  _FinishersStatus _status = _FinishersStatus.loading;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _status = _FinishersStatus.loading);
    final result = await widget.cloud.fetchBookFinishers(
      widget.book.id,
      limit: 50,
    );
    if (!mounted) return;
    setState(() {
      if (result == null) {
        _status = _FinishersStatus.offline;
      } else {
        // Sort: current user first, then alphabetically.
        final me = result.where((r) => r['uid'] == widget.currentUid).toList();
        final others = result
            .where((r) => r['uid'] != widget.currentUid)
            .toList()
          ..sort(
            (a, b) => (a['username'] as String? ?? '')
                .compareTo(b['username'] as String? ?? ''),
          );
        _rows = [...me, ...others];
        _status = _FinishersStatus.loaded;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bookName = widget.book.nameFor(strings.lang);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Icon(Icons.people, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.finishersTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          bookName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_status == _FinishersStatus.loaded && _rows.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        strings.finishersCount(_rows.length),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body
            Expanded(child: _buildBody(theme, scheme, strings, scrollController)),
          ],
        );
      },
    );
  }

  Widget _buildBody(
    ThemeData theme,
    ColorScheme scheme,
    dynamic strings,
    ScrollController scrollController,
  ) {
    if (_status == _FinishersStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_status == _FinishersStatus.offline) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 48, color: scheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                strings.finishersOffline as String,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _load,
                child: Text(strings.leaderboardRetry as String),
              ),
            ],
          ),
        ),
      );
    }

    if (_rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 48, color: scheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                strings.finishersEmpty as String,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, i) {
        final row = _rows[i];
        final username = row['username'] as String? ?? '?';
        final isMe = row['uid'] == widget.currentUid;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? scheme.primaryContainer : scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMe
                  ? scheme.primary.withAlpha(100)
                  : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person,
                size: 18,
                color: isMe ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  username,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isMe ? FontWeight.w700 : FontWeight.w500,
                    color: isMe
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isMe)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    strings.finishersYou as String,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
