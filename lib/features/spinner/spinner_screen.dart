import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/account_controller.dart';
import '../../data/books_data.dart';
import '../../data/cloud_repository.dart';
import '../../data/progress_controller.dart';
import '../../data/quiz_repository.dart';
import '../../models/book.dart';
import '../../settings_scope.dart';
import '../../theme/app_theme.dart';
import '../books/chapter_screen.dart';

/// Scope for the spinner wheel.
enum _SpinScope { all, oldTestament, newTestament }

class SpinnerScreen extends StatefulWidget {
  const SpinnerScreen({
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
  State<SpinnerScreen> createState() => _SpinnerScreenState();
}

class _SpinnerScreenState extends State<SpinnerScreen>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  late final AnimationController _ctrl;

  bool _includeFinished = false;
  _SpinScope _scope = _SpinScope.all;
  late List<Book> _wheel;
  bool _spinning = false;

  // The wheel turns from [_from] to [_to] radians while the controller runs.
  double _from = 0;
  double _to = 0;
  double get _angle =>
      _from + (_to - _from) * Curves.easeOutQuart.transform(_ctrl.value);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _wheel = _pickBooks();
    widget.progress.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    widget.progress.removeListener(_onProgressChanged);
    _ctrl.dispose();
    super.dispose();
  }

  /// Books filtered by scope and (optionally) finished status.
  List<Book> _pickBooks() {
    return allBooks
        .where((b) {
          // Scope filter.
          final inScope = switch (_scope) {
            _SpinScope.all => true,
            _SpinScope.oldTestament =>
              b.section == Section.oldTestament ||
                  b.section == Section.deuterocanonical,
            _SpinScope.newTestament => b.section == Section.newTestament,
          };
          if (!inScope) return false;
          // Finished filter.
          if (!_includeFinished && widget.progress.isCompleted(b)) return false;
          return true;
        })
        .toList(growable: false);
  }

  void _refreshWheel() {
    setState(() {
      _wheel = _pickBooks();
    });
  }

  void _onProgressChanged() {
    if (mounted && !_spinning) _refreshWheel();
  }

  void _spin() {
    if (_spinning || _wheel.isEmpty) return;
    final n = _wheel.length;
    final sliceAngle = 2 * pi / n;
    final k = _random.nextInt(n);

    final current = _angle % (2 * pi);
    final target = 2 * pi - (k + 0.5) * sliceAngle;
    final delta = (target - current) % (2 * pi);

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _ctrl.duration = reduceMotion ? Duration.zero : const Duration(seconds: 4);

    _from = _angle;
    _to = _from + 5 * 2 * pi + delta;
    setState(() => _spinning = true);

    _ctrl.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      // Keep the final position for the next spin.
      _from = _to;
      setState(() => _spinning = false);
      _showResultDialog(_wheel[k]);
    });
  }

  Future<void> _showResultDialog(Book book) async {
    if (!mounted) return;
    final strings = context.s;
    final name = book.nameFor(strings.lang);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: name,
      transitionDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 280),
      transitionBuilder: (ctx, anim, _, child) {
        if (reduceMotion) return child;
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
      pageBuilder: (ctx, anim1, anim2) => _ResultDialog(
        book: book,
        name: name,
        onOpen: () {
          Navigator.of(ctx).pop();
          if (mounted) _openBook(book);
        },
        onSpinAgain: () {
          Navigator.of(ctx).pop();
          if (mounted) _spin();
        },
      ),
    );

    // Refresh wheel when dialog is dismissed (e.g. user marked chapters).
    if (mounted) _refreshWheel();
  }

  List<Color> _sliceColors(BuildContext context, int n) {
    final light = Theme.of(context).brightness == Brightness.light;
    final a = light ? const Color(0xFF164B77) : const Color(0xFF2C5C9E);
    final b = light ? const Color(0xFF2B7A6C) : const Color(0xFF2E8B78);
    final c = light ? const Color(0xFF3B6E8F) : const Color(0xFF3F76A8);
    return [
      for (var i = 0; i < n; i++)
        (n.isOdd && n > 1 && i == n - 1) ? c : (i.isEven ? a : b),
    ];
  }

  void _openBook(Book book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChapterScreen(
          book: book,
          progress: widget.progress,
          account: widget.account,
          cloud: widget.cloud,
          quizRepo: widget.quizRepo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strings = context.s;
    final names = [for (final b in _wheel) b.nameFor(strings.lang)];

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.spinTitle),
        actions: [
          // ---- Scope dropdown (Task 2) ----
          Semantics(
            label: strings.spinScopeSemantics,
            child: PopupMenuButton<_SpinScope>(
              enabled: !_spinning,
              initialValue: _scope,
              tooltip: strings.spinScopeSemantics,
              onSelected: (s) {
                if (s == _scope) return;
                setState(() => _scope = s);
                _refreshWheel();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _SpinScope.all,
                  child: Text(strings.scopeAll),
                ),
                PopupMenuItem(
                  value: _SpinScope.oldTestament,
                  child: Text(strings.scopeOldTestament),
                ),
                PopupMenuItem(
                  value: _SpinScope.newTestament,
                  child: Text(strings.scopeNewTestament),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      switch (_scope) {
                        _SpinScope.all => strings.scopeAll,
                        _SpinScope.oldTestament => strings.scopeOldTestament,
                        _SpinScope.newTestament => strings.scopeNewTestament,
                      },
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _spinning
                            ? scheme.onSurface.withValues(alpha: 0.38)
                            : scheme.onSurface,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: _spinning
                          ? scheme.onSurface.withValues(alpha: 0.38)
                          : scheme.onSurface,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            // ---- Wheel or empty state (Tasks 2, 3) ----
            if (_wheel.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: doneColor(context)),
                ),
                child: Text(
                  _scope == _SpinScope.all
                      ? strings.allBooksFinished
                      : strings.scopeAllBooksFinished,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              )
            else
              // Pointer arrow sits above the wheel; both fit without clipping.
              Column(
                children: [
                  // Pointer arrow (Task 3 — visible above wheel).
                  Icon(
                    Icons.arrow_drop_down,
                    size: 48,
                    color: scheme.onSurface,
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Semantics(
                        label: strings.wheelSemantics(names),
                        child: AnimatedBuilder(
                          animation: _ctrl,
                          builder: (context, _) => CustomPaint(
                            size: Size.infinite,
                            painter: _WheelPainter(
                              names: names,
                              colors: _sliceColors(context, names.length),
                              rotation: _angle,
                              hubColor: scheme.surface,
                              lineColor: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (_wheel.isNotEmpty)
              Text(
                strings.wheelCount(_wheel.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(strings.includeFinished),
              value: _includeFinished,
              onChanged: _spinning
                  ? null
                  : (v) {
                      _includeFinished = v;
                      _refreshWheel();
                    },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_spinning || _wheel.isEmpty) ? null : _spin,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(strings.spinButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Result dialog (Task 4) ----
class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.book,
    required this.name,
    required this.onOpen,
    required this.onSpinAgain,
  });

  final Book book;
  final String name;
  final VoidCallback onOpen;
  final VoidCallback onSpinAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strings = context.s;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              strings.readLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.chapterCountLabel(book.totalChapters),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onOpen,
                child: Text(strings.openBook),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSpinAgain,
                child: Text(strings.spinAgain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws the wheel. Slice 0 starts at the top and slices go clockwise.
class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.names,
    required this.colors,
    required this.rotation,
    required this.hubColor,
    required this.lineColor,
  });

  final List<String> names;
  final List<Color> colors;
  final double rotation;
  final Color hubColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final n = names.length;
    if (n == 0) return;

    final radius = size.shortestSide / 2;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: radius - 2);
    final sweep = 2 * pi / n;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final fill = Paint()..style = PaintingStyle.fill;
    final divider = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = n > 30 ? 0.7 : 1.5
      ..color = Colors.white;

    final local = Rect.fromCircle(center: Offset.zero, radius: rect.width / 2);
    for (var i = 0; i < n; i++) {
      final start = -pi / 2 + i * sweep;
      fill.color = colors[i];
      canvas.drawArc(local, start, sweep, true, fill);
      if (n > 1) canvas.drawArc(local, start, sweep, true, divider);
    }

    // Labels run along each slice and end near the rim.
    final labelEnd = radius * 0.94;
    final maxFont = (radius * 0.09).clamp(11.0, 18.0).toDouble();
    for (var i = 0; i < n; i++) {
      final probe = TextPainter(
        text: TextSpan(
          text: names[i],
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final k = probe.width / 10;
      probe.dispose();

      final fitSlice = sweep * labelEnd / (1.15 + sweep * k);
      final fitLength = (labelEnd - radius * 0.2) / k;
      final fontSize = min(maxFont, max(5.0, min(fitSlice, fitLength)));

      final tp = TextPainter(
        text: TextSpan(
          text: names[i],
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      canvas.save();
      canvas.rotate(-pi / 2 + (i + 0.5) * sweep);
      tp.paint(canvas, Offset(labelEnd - tp.width, -tp.height / 2));
      canvas.restore();
      tp.dispose();
    }
    canvas.restore();

    // Rim and hub stay still while the wheel turns.
    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = lineColor,
    );
    canvas.drawCircle(center, radius * 0.12, Paint()..color = hubColor);
    canvas.drawCircle(
      center,
      radius * 0.12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.rotation != rotation ||
      !listEquals(old.names, names) ||
      !listEquals(old.colors, colors) ||
      old.hubColor != hubColor ||
      old.lineColor != lineColor;
}
