import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/rank_system.dart';
import '../../l10n/strings.dart';
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
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: totalMs),
    );

    _hintCtrl = AnimationController(
      vsync: this,
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 400),
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
    // Compare both tier and division, including entry to / exit from the top.
    if (widget.before.tier == widget.after.tier &&
        widget.before.division == widget.after.division) {
      if (widget.after.isTopTier) {
        return widget.isGain
            ? _ChangeKind.topTierGain
            : _ChangeKind.topTierLoss;
      }
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
    final showHighest = !widget.isGain && maxRank.isHigherThan(widget.after);

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
      curve: const Interval(0.60, 0.85, curve: Curves.easeIn),
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
  final Strings strings;
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
          strings.rankName(after),
          textAlign: TextAlign.center,
          style: nameStyle,
        ),
      );
    }

    // Crossfade rank names
    final fadeOld = CurvedAnimation(
      parent: ctrl,
      curve: const Interval(0.60, 0.85, curve: Curves.easeIn),
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
            strings.rankName(before),
            textAlign: TextAlign.center,
            style: nameStyle,
          ),
        ),
        FadeTransition(
          opacity: fadeNew,
          child: Text(
            strings.rankName(after),
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
    required this.accent,
    required this.strings,
  });

  final AnimationController ctrl;
  final _ChangeKind kind;
  final RankInfo before;
  final RankInfo after;
  final bool isGain;
  final Color accent;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    if (kind == _ChangeKind.topTierGain || kind == _ChangeKind.topTierLoss) {
      return _TopTierCounter(
        ctrl: ctrl,
        startCount: before.topStars,
        endCount: after.topStars,
        accent: accent,
      );
    }

    final rankUp = kind == _ChangeKind.rankUp;
    final rankDown = kind == _ChangeKind.rankDown;
    final rankChange = rankUp || rankDown;
    final t = ctrl.value;
    final flight = const Interval(
      0.15,
      0.40,
      curve: Curves.easeOutCubic,
    ).transform(t);
    final fading = const Interval(
      0.15,
      0.45,
      curve: Curves.easeInOut,
    ).transform(t);
    final transition = const Interval(
      0.60,
      0.85,
      curve: Curves.easeOut,
    ).transform(t);
    final burst = const Interval(0.40, 0.60).transform(t);
    final landed = t >= 0.40;

    Widget row(RankInfo rank, {bool departing = false}) {
      if (rank.isTopTier) {
        return Opacity(
          opacity: departing ? 1 - fading : 1,
          child: Text(
            strings.rankStars(rank.topStars),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        );
      }
      final losing = departing && !isGain;
      return _StarRow(
        filled: departing && !rankChange && isGain && landed
            ? after.starsInDivision
            : rank.starsInDivision,
        accent: accent,
        fadingIndex: losing ? rank.starsInDivision - 1 : null,
        fadingOpacity: 1 - fading,
      );
    }

    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (rankChange) ...[
            if (transition < 1)
              Opacity(
                opacity: 1 - transition,
                child: row(before, departing: true),
              ),
            if (transition > 0) Opacity(opacity: transition, child: row(after)),
          ] else
            row(before, departing: true),
          // The fifth star bursts above a full row on promotion. Ordinary gains
          // land directly in the next outline slot of the four-star row.
          if (isGain && t >= 0.15 && !landed)
            Transform.translate(
              key: const ValueKey('flying-star'),
              offset: Offset(
                rankUp ? 0 : (after.starsInDivision - 2.5) * 36,
                -80 * (1 - flight),
              ),
              child: Opacity(
                opacity: flight,
                child: Icon(Icons.star_rounded, size: 32, color: accent),
              ),
            ),
          if (rankUp && burst > 0 && burst < 1)
            _StarBurst(
              progress: burst,
              tierChange: before.tier != after.tier,
              color: accent,
            ),
          if (kind == _ChangeKind.sameDivisionGain && landed && t < 0.70)
            Transform.translate(
              offset: Offset((after.starsInDivision - 2.5) * 36, 0),
              child: Opacity(
                opacity: (1 - (t - 0.40) / 0.30).clamp(0.0, 1.0),
                child: Icon(
                  Icons.star_rounded,
                  size: 34,
                  color: accent,
                  shadows: [Shadow(color: accent, blurRadius: 16)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({
    required this.filled,
    required this.accent,
    this.fadingIndex,
    this.fadingOpacity = 1,
  });

  final int filled;
  final Color accent;
  final int? fadingIndex;
  final double fadingOpacity;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('animated-star-row'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < kStarsPerDivision; i++)
          SizedBox(
            width: 36,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (i >= filled || (i == fadingIndex && fadingOpacity < 1))
                  Icon(
                    Icons.star_outline_rounded,
                    size: 28,
                    color: accent.withAlpha(70),
                  ),
                if (i < filled && (i != fadingIndex || fadingOpacity > 0))
                  Opacity(
                    opacity: i == fadingIndex ? fadingOpacity : 1,
                    child: Icon(Icons.star_rounded, size: 28, color: accent),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A larger ring of sparks celebrates crossing a tier boundary.
class _StarBurst extends StatelessWidget {
  const _StarBurst({
    required this.progress,
    required this.tierChange,
    required this.color,
  });

  final double progress;
  final bool tierChange;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final count = tierChange ? 12 : 8;
    final radius = (tierChange ? 100 : 60) * Curves.easeOut.transform(progress);
    return Opacity(
      key: ValueKey(
        tierChange ? 'tier-promotion-burst' : 'division-promotion-burst',
      ),
      opacity: 1 - progress,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < count; i++)
            Transform.translate(
              offset: Offset(
                math.cos(i * 2 * math.pi / count) * radius,
                math.sin(i * 2 * math.pi / count) * radius,
              ),
              child: Icon(
                Icons.star_rounded,
                size: tierChange ? 18 : 12,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

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
  final Strings strings;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final opacity = CurvedAnimation(
      parent: ctrl,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    );
    final slide =
        CurvedAnimation(
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
          isGain ? strings.starPlusOne : strings.starMinusOne,
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
  final Strings strings;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: ctrl,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );
    final rankName = strings.rankName(after);
    final message = kind == _ChangeKind.rankUp
        ? strings.starRankUp(rankName)
        : strings.starRankDown(rankName);

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
