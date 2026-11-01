import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/rank_system.dart';
import '../../settings_scope.dart';
import 'rank_badge.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public helper: push the StarChangeScreen as a fade route.
// ─────────────────────────────────────────────────────────────────────────────

Future<void> pushStarChangeScreen({
  required BuildContext context,
  required RankInfo before,
  required RankInfo after,
  required int maxStarsEver,
  required bool isGain,
}) async {
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim, secondAnim) => StarChangeScreen(
        before: before,
        after: after,
        maxStarsEver: maxStarsEver,
        isGain: isGain,
      ),
      transitionsBuilder: (ctx, animation, secondAnim, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// StarChangeScreen
// ─────────────────────────────────────────────────────────────────────────────

class StarChangeScreen extends StatefulWidget {
  const StarChangeScreen({
    super.key,
    required this.before,
    required this.after,
    required this.maxStarsEver,
    required this.isGain,
  });

  /// Rank *before* the chapter was marked / un-marked.
  final RankInfo before;

  /// Rank *after* the chapter was marked / un-marked.
  final RankInfo after;

  /// The lifetime-high star count (for the "highest rank still" line).
  final int maxStarsEver;

  /// true = gained a star, false = lost one.
  final bool isGain;

  @override
  State<StarChangeScreen> createState() => _StarChangeScreenState();
}

class _StarChangeScreenState extends State<StarChangeScreen>
    with TickerProviderStateMixin {
  // ── animation state ────────────────────────────────────────────────────────
  late final AnimationController _mainCtrl;
  late final AnimationController _hintCtrl;
  bool _canClose = false;
  Timer? _closeTimer;

  // What kind of transition are we showing?
  late final _ChangeKind _kind;

  @override
  void initState() {
    super.initState();
    _kind = _classifyChange();

    const totalMs = 1500;
    final reducedMotion = _reducedMotion;

    _mainCtrl = AnimationController(
      vsync: this,
      duration: reducedMotion ? Duration.zero : const Duration(milliseconds: totalMs),
    );

    _hintCtrl = AnimationController(
      vsync: this,
      duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 400),
    );

    if (reducedMotion) {
      _canClose = true;
      _hintCtrl.value = 1.0;
      _mainCtrl.value = 1.0;
      if (widget.isGain) HapticFeedback.lightImpact();
    } else {
      _mainCtrl.addStatusListener(_onMainAnimStatus);
      _mainCtrl.forward();
    }
  }

  void _onMainAnimStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    // Haptics on completion
    if (widget.isGain) {
      if (_kind == _ChangeKind.rankUp) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
    _closeTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _canClose = true);
        _hintCtrl.forward();
      }
    });
  }

  bool get _reducedMotion {
    // Read during build; cache would require didChangeDependencies.
    // Called once in initState so we check WidgetsBinding.
    final binding = WidgetsBinding.instance;
    return binding.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _mainCtrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
  }

  // ── classification ─────────────────────────────────────────────────────────

  _ChangeKind _classifyChange() {
    final bDiv = widget.before.division;
    final aDiv = widget.after.division;
    // Top tier
    if (aDiv == null) {
      return widget.isGain ? _ChangeKind.topTierGain : _ChangeKind.topTierLoss;
    }
    // Same rank tier + same division → just star count changed
    if (widget.before.tier == widget.after.tier && bDiv == aDiv) {
      return widget.isGain
          ? _ChangeKind.sameDivisionGain
          : _ChangeKind.sameDivisionLoss;
    }
    return widget.isGain ? _ChangeKind.rankUp : _ChangeKind.rankDown;
  }

  // ── colors ─────────────────────────────────────────────────────────────────

  Color _bgColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (widget.isGain) {
      return brightness == Brightness.light
          ? const Color(0xFFFFF8E1)
          : const Color(0xFF2A1F00);
    } else {
      return brightness == Brightness.light
          ? const Color(0xFFECEFF4)
          : const Color(0xFF141C2A);
    }
  }

  Color _accentColor(BuildContext context) {
    if (widget.isGain) {
      return const Color(0xFFF9A825); // golden
    } else {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  // ── tap-to-close ───────────────────────────────────────────────────────────

  void _tryClose() {
    if (_canClose) Navigator.of(context).pop();
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    final accent = _accentColor(context);
    final bg = _bgColor(context);
    final scheme = Theme.of(context).colorScheme;

    // Highest-rank line: show only on loss and only when max rank > current
    final maxRank = rankForStars(widget.maxStarsEver);
    final showHighest =
        !widget.isGain && maxRank.isHigherThan(widget.after);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tryClose,
      child: Material(
        color: bg,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: AnimatedBuilder(
                animation: _mainCtrl,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Badge ──────────────────────────────────────────────
                      _AnimatedBadge(
                        ctrl: _mainCtrl,
                        kind: _kind,
                        before: widget.before,
                        after: widget.after,
                        accent: accent,
                      ),
                      const SizedBox(height: 16),

                      // ── Rank name ──────────────────────────────────────────
                      _AnimatedRankName(
                        ctrl: _mainCtrl,
                        kind: _kind,
                        before: widget.before,
                        after: widget.after,
                        strings: strings,
                        accent: accent,
                      ),
                      const SizedBox(height: 24),

                      // ── Star progress ──────────────────────────────────────
                      _AnimatedStarProgress(
                        ctrl: _mainCtrl,
                        kind: _kind,
                        before: widget.before,
                        after: widget.after,
                        isGain: widget.isGain,
                        totalStars: widget.isGain
                            ? widget.maxStarsEver
                            : widget.maxStarsEver - 1,
                        accent: accent,
                        strings: strings,
                      ),
                      const SizedBox(height: 20),

                      // ── Delta label (+1 ★ / -1 ★) ─────────────────────────
                      _DeltaLabel(
                        ctrl: _mainCtrl,
                        isGain: widget.isGain,
                        strings: strings,
                        accent: accent,
                      ),
                      const SizedBox(height: 12),

                      // ── Rank-up / rank-down message ────────────────────────
                      if (_kind == _ChangeKind.rankUp ||
                          _kind == _ChangeKind.rankDown)
                        _RankChangeMessage(
                          ctrl: _mainCtrl,
                          kind: _kind,
                          after: widget.after,
                          strings: strings,
                          scheme: scheme,
                        ),

                      // ── Highest rank still line ────────────────────────────
                      if (showHighest) ...[
                        const SizedBox(height: 12),
                        Opacity(
                          opacity: _mainCtrl.value,
                          child: Text(
                            strings.starHighestStill(strings.rankName(maxRank)),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),

                      // ── Tap-to-continue hint ───────────────────────────────
                      FadeTransition(
                        opacity: _hintCtrl,
                        child: Text(
                          strings.starTapToContinue,
                          style: TextStyle(
                            fontSize: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Change classification
// ─────────────────────────────────────────────────────────────────────────────

enum _ChangeKind {
  sameDivisionGain,
  sameDivisionLoss,
  rankUp,
  rankDown,
  topTierGain,
  topTierLoss,
}

// ─────────────────────────────────────────────────────────────────────────────
// _AnimatedBadge
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedBadge extends StatelessWidget {
  const _AnimatedBadge({
    required this.ctrl,
    required this.kind,
    required this.before,
    required this.after,
    required this.accent,
  });

  final AnimationController ctrl;
  final _ChangeKind kind;
  final RankInfo before;
  final RankInfo after;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isRankChange =
        kind == _ChangeKind.rankUp || kind == _ChangeKind.rankDown;

    if (!isRankChange) {
      // Simple scale-in for the badge
      final scale = CurvedAnimation(
        parent: ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      );
      return ScaleTransition(
        scale: scale,
        child: RankBadge(tier: after.tier, size: 80),
      );
    }

    // Rank change: crossfade from old to new badge
    final fadeOld = CurvedAnimation(
      parent: ctrl,
      curve: const Interval(0.45, 0.65, curve: Curves.easeIn),
    );
    final fadeNew = CurvedAnimation(
      parent: ctrl,
      curve: const Interval(0.60, 0.85, curve: Curves.easeOut),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        FadeTransition(
          opacity: ReverseAnimation(fadeOld),
          child: RankBadge(tier: before.tier, size: 80),
        ),
        FadeTransition(
          opacity: fadeNew,
          child: RankBadge(tier: after.tier, size: 80),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AnimatedRankName
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedRankName extends StatelessWidget {
  const _AnimatedRankName({
    required this.ctrl,
    required this.kind,
    required this.before,
    required this.after,
    required this.strings,
    required this.accent,
  });

  final AnimationController ctrl;
  final _ChangeKind kind;
  final RankInfo before;
  final RankInfo after;
  final dynamic strings;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRankChange =
        kind == _ChangeKind.rankUp || kind == _ChangeKind.rankDown;

    final nameStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: accent,
    );

    if (!isRankChange) {
      final fade = CurvedAnimation(
        parent: ctrl,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
      );
      return FadeTransition(
        opacity: fade,
        child: Text(
          strings.rankName(after) as String,
          textAlign: TextAlign.center,
          style: nameStyle,
        ),
      );
    }

    // Crossfade rank names
    final fadeOld = CurvedAnimation(
      parent: ctrl,
      curve: const Interval(0.45, 0.65, curve: Curves.easeIn),
    );
    final fadeNew = CurvedAnimation(
      parent: ctrl,
      curve: const Interval(0.60, 0.85, curve: Curves.easeOut),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        FadeTransition(
          opacity: ReverseAnimation(fadeOld),
          child: Text(
            strings.rankName(before) as String,
            textAlign: TextAlign.center,
            style: nameStyle,
          ),
        ),
        FadeTransition(
          opacity: fadeNew,
          child: Text(
            strings.rankName(after) as String,
            textAlign: TextAlign.center,
            style: nameStyle,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AnimatedStarProgress
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedStarProgress extends StatelessWidget {
  const _AnimatedStarProgress({
    required this.ctrl,
    required this.kind,
    required this.before,
    required this.after,
    required this.isGain,
    required this.totalStars,
    required this.accent,
    required this.strings,
  });

  final AnimationController ctrl;
  final _ChangeKind kind;
  final RankInfo before;
  final RankInfo after;
  final bool isGain;
  final int totalStars;
  final Color accent;
  final dynamic strings;

  @override
  Widget build(BuildContext context) {
    // Top tier: animate total star count
    if (kind == _ChangeKind.topTierGain || kind == _ChangeKind.topTierLoss) {
      return _TopTierCounter(
        ctrl: ctrl,
        startCount: isGain ? totalStars - 1 : totalStars + 1,
        endCount: totalStars,
        accent: accent,
      );
    }

    // For rank changes the two halves of the animation use different divisions.
    // Phase 1 (0.15–0.65): animate within the BEFORE division (fill/drain).
    // Phase 2 (0.65–1.00): crossfade to AFTER division, show endFilled.
    final isRankChange =
        kind == _ChangeKind.rankUp || kind == _ChangeKind.rankDown;

    final beforeTotal = before.starsForDivision; // used in phase 1
    final afterTotal = after.starsForDivision;   // used in phase 2
    final startFilled = before.starsInDivision;
    final endFilled = after.starsInDivision;

    // Phase-1 animation end value (relative to beforeTotal):
    final phase1End = kind == _ChangeKind.rankUp
        ? beforeTotal.toDouble()  // fill to full
        : kind == _ChangeKind.rankDown
            ? 0.0                 // drain to empty
            : endFilled.toDouble(); // same-division

    // Single animation drives phase 1 (and phase 2 is driven by crossfade).
    final barAnim = CurvedAnimation(
      parent: ctrl,
      curve: const Interval(0.15, 0.65, curve: Curves.easeInOut),
    ).drive(Tween<double>(begin: startFilled.toDouble(), end: phase1End));

    // Phase-2 opacity (crossfade in after rank after 0.65).
    final phase2Opacity = CurvedAnimation(
      parent: ctrl,
      curve: const Interval(0.65, 0.90, curve: Curves.easeOut),
    );

    // Use the DISPLAYED total for bar/row rendering.
    // Phase 1: use beforeTotal. Phase 2: use afterTotal (via crossfade).
    final total = isRankChange ? beforeTotal : afterTotal;

    if (total <= 10) {
      // Star row
      return AnimatedBuilder(
        animation: Listenable.merge([barAnim, phase2Opacity]),
        builder: (context, _) {
          if (isRankChange && phase2Opacity.value > 0.5) {
            // Phase 2: show after-division row at endFilled / afterTotal
            return Opacity(
              opacity: phase2Opacity.value,
              child: _StarRow(
                filled: endFilled,
                total: afterTotal,
                accent: accent,
                isNew: -1,
              ),
            );
          }
          final filled = barAnim.value.round();
          return _StarRow(
            filled: filled,
            total: total,
            accent: accent,
            isNew: kind == _ChangeKind.sameDivisionGain ? filled - 1 : -1,
          );
        },
      );
    }

    // Progress bar
    return AnimatedBuilder(
      animation: Listenable.merge([barAnim, phase2Opacity]),
      builder: (context, _) {
        // Phase 2 of rank change: animate to after-division values.
        if (isRankChange && phase2Opacity.value > 0.5) {
          final ratio = (endFilled / afterTotal).clamp(0.0, 1.0);
          return Opacity(
            opacity: phase2Opacity.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    backgroundColor: accent.withAlpha(40),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.rankStarProgress(endFilled, afterTotal) as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
          );
        }
        final filled = barAnim.value.round();
        final ratio = (filled / total).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                backgroundColor: accent.withAlpha(40),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.rankStarProgress(filled, total) as String,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StarRow – row of filled/outline star icons with the "newest" star scaled up
// ─────────────────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  const _StarRow({
    required this.filled,
    required this.total,
    required this.accent,
    required this.isNew,
  });

  final int filled;
  final int total;
  final Color accent;

  /// Index of the "new" star (gains a glow). -1 = none.
  final int isNew;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          _buildStar(i),
      ],
    );
  }

  Widget _buildStar(int i) {
    final isFilled = i < filled;
    final isNewStar = i == isNew && isFilled;
    final color = isFilled ? accent : accent.withAlpha(70);
    final icon = Icon(
      isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
      size: isNewStar ? 32 : 28,
      color: color,
    );
    if (isNewStar) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha(120),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: icon,
      );
    }
    return icon;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TopTierCounter
// ─────────────────────────────────────────────────────────────────────────────

class _TopTierCounter extends StatelessWidget {
  const _TopTierCounter({
    required this.ctrl,
    required this.startCount,
    required this.endCount,
    required this.accent,
  });

  final AnimationController ctrl;
  final int startCount;
  final int endCount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: ctrl,
      curve: const Interval(0.15, 0.75, curve: Curves.easeInOut),
    ).drive(IntTween(begin: startCount, end: endCount));

    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Text(
        '${anim.value} ★',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DeltaLabel  (+1 ★ or -1 ★ floating label)
// ─────────────────────────────────────────────────────────────────────────────

class _DeltaLabel extends StatelessWidget {
  const _DeltaLabel({
    required this.ctrl,
    required this.isGain,
    required this.strings,
    required this.accent,
  });

  final AnimationController ctrl;
  final bool isGain;
  final dynamic strings;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final opacity = CurvedAnimation(
      parent: ctrl,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    );
    final slide = CurvedAnimation(
      parent: ctrl,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    ).drive(
      Tween<Offset>(
        begin: Offset(0, isGain ? 0.5 : -0.5),
        end: Offset.zero,
      ),
    );

    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: opacity,
        child: Text(
          isGain
              ? strings.starPlusOne as String
              : strings.starMinusOne as String,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RankChangeMessage
// ─────────────────────────────────────────────────────────────────────────────

class _RankChangeMessage extends StatelessWidget {
  const _RankChangeMessage({
    required this.ctrl,
    required this.kind,
    required this.after,
    required this.strings,
    required this.scheme,
  });

  final AnimationController ctrl;
  final _ChangeKind kind;
  final RankInfo after;
  final dynamic strings;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: ctrl,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );
    final rankName = strings.rankName(after) as String;
    final message = kind == _ChangeKind.rankUp
        ? strings.starRankUp(rankName) as String
        : strings.starRankDown(rankName) as String;

    return FadeTransition(
      opacity: fade,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: kind == _ChangeKind.rankUp
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

