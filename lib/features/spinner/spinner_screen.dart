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
import '../../widgets/app_header.dart';
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
    final a = Theme.of(context).colorScheme.surfaceContainer;
    final b = Theme.of(context).colorScheme.primaryContainer;
    final c = Theme.of(context).colorScheme.surface;
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
    final headerColor = theme.appBarTheme.foregroundColor ?? scheme.onSurface;
    final strings = context.s;
    final names = [for (final b in _wheel) b.nameFor(strings.lang)];

    return Scaffold(
      appBar: appHeader(
        context,
        title: strings.spinTitle,
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
                            ? headerColor.withValues(alpha: 0.38)
                            : headerColor,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: _spinning
                          ? headerColor.withValues(alpha: 0.38)
                          : headerColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = max(1.0, constraints.maxWidth - 32);
            double textHeight(String text, TextStyle? style, double maxWidth) {
              final painter = TextPainter(
                text: TextSpan(text: text, style: style),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: maxWidth);
              final height = painter.height;
              painter.dispose();
              return height;
            }

            final headingHeight = textHeight(
              strings.spinHeading,
              theme.textTheme.headlineMedium,
              width,
            );
            final countHeight = textHeight(
              strings.wheelCount(_wheel.length),
              theme.textTheme.bodySmall,
              width,
            );
            final switchHeight = max(
              56.0,
              textHeight(
                    strings.includeFinished,
                    theme.textTheme.bodyMedium,
                    max(1, width - 120),
                  ) +
                  8,
            );
            final buttonHeight = max(
              50.0,
              textHeight(
                    strings.spinButton,
                    theme.textTheme.labelLarge,
                    max(1, width - 48),
                  ) +
                  30,
            );
            // Reserve actual scaled text/control heights. Only small viewports or
            // larger text need scrolling once the face reaches its minimum size.
            final fixedHeight =
                20 +
                headingHeight +
                6 +
                24 +
                4 +
                countHeight +
                6 +
                switchHeight +
                8 +
                8 +
                buttonHeight;
            final wheelSize = (constraints.maxHeight - fixedHeight).clamp(
              160.0,
              min(340.0, width).clamp(160.0, 340.0),
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      strings.spinHeading,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                          size: 24,
                          color: scheme.tertiary,
                        ),
                        SizedBox.square(
                          dimension: wheelSize,
                          child: SizedBox.expand(
                            child: Semantics(
                              label: strings.wheelSemantics(names),
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  foregroundPainter: _WheelFramePainter(
                                    hubColor: scheme.primaryContainer,
                                    lineColor: scheme.outlineVariant,
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _ctrl,
                                    child: RepaintBoundary(
                                      child: CustomPaint(
                                        size: Size.infinite,
                                        painter: _WheelPainter(
                                          names: names,
                                          colors: _sliceColors(
                                            context,
                                            names.length,
                                          ),
                                          lineColor: scheme.outlineVariant,
                                        ),
                                      ),
                                    ),
                                    builder: (context, child) =>
                                        Transform.rotate(
                                          angle: _angle,
                                          child: child,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  if (_wheel.isNotEmpty)
                    Text(
                      strings.wheelCount(_wheel.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height:
                        switchHeight +
                        8, // Includes the Card's vertical margin.
                    child: Card(
                      child: ListTileTheme(
                        data: ListTileTheme.of(
                          context,
                        ).copyWith(minVerticalPadding: 4),
                        child: SwitchListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          title: Text(
                            strings.includeFinished,
                            style: theme.textTheme.bodyMedium,
                          ),
                          value: _includeFinished,
                          onChanged: _spinning
                              ? null
                              : (v) {
                                  _includeFinished = v;
                                  _refreshWheel();
                                },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: FilledButton(
                      onPressed: (_spinning || _wheel.isEmpty) ? null : _spin,
                      child: Text(strings.spinButton),
                    ),
                  ),
                ],
              ),
            );
          },
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
    required this.lineColor,
  }) : _divider = (Paint()
         ..style = PaintingStyle.stroke
         ..strokeWidth = names.length > 30 ? 0.7 : 1.5
         ..color = lineColor);

  final List<String> names;
  final List<Color> colors;
  final Color lineColor;
  final Paint _fill = Paint()..style = PaintingStyle.fill;
  final Paint _divider;

  // Independent of radius; each book is measured only once per face.
  late final List<double> _labelWidthFactors = [
    for (final name in names) _measureLabel(name),
  ];

  static double _measureLabel(String name) {
    final probe = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          fontFamily: AppTypography.sans,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final factor = probe.width / 10;
    probe.dispose();
    return factor;
  }

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

    final local = Rect.fromCircle(center: Offset.zero, radius: rect.width / 2);
    for (var i = 0; i < n; i++) {
      final start = -pi / 2 + i * sweep;
      _fill.color = colors[i];
      canvas.drawArc(local, start, sweep, true, _fill);
      if (n > 1) canvas.drawArc(local, start, sweep, true, _divider);
    }

    // Labels run along each slice and end near the rim.
    final labelEnd = radius * 0.94;
    final maxFont = (radius * 0.09).clamp(11.0, 18.0).toDouble();
    for (var i = 0; i < n; i++) {
      final k = _labelWidthFactors[i];

      final fitSlice = sweep * labelEnd / (1.15 + sweep * k);
      final fitLength = (labelEnd - radius * 0.2) / k;
      final fontSize = min(maxFont, max(5.0, min(fitSlice, fitLength)));

      final tp = TextPainter(
        text: TextSpan(
          text: names[i],
          style: TextStyle(
            color:
                ThemeData.estimateBrightnessForColor(colors[i]) ==
                    Brightness.dark
                ? AppPalette.cream
                : AppPalette.ink,
            fontFamily: AppTypography.sans,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
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
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      !listEquals(old.names, names) ||
      !listEquals(old.colors, colors) ||
      old.lineColor != lineColor;
}

/// Circular frame stays stationary while the cached face rotates underneath.
class _WheelFramePainter extends CustomPainter {
  _WheelFramePainter({required this.hubColor, required this.lineColor})
    : _hub = (Paint()..color = hubColor),
      _rim = (Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = lineColor);

  final Color hubColor;
  final Color lineColor;
  final Paint _hub;
  final Paint _rim;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(center, radius - 2, _rim);
    canvas.drawCircle(center, radius * 0.12, _hub);
    canvas.drawCircle(center, radius * 0.12, _rim);
  }

  @override
  bool shouldRepaint(_WheelFramePainter old) =>
      old.hubColor != hubColor || old.lineColor != lineColor;
}
