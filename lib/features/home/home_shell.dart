import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/account_controller.dart';
import '../../data/cloud_repository.dart';
import '../../data/progress_controller.dart';
import '../../data/quiz_repository.dart';
import '../../settings_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/spin_wheel_icon.dart';
import '../../widgets/floating_pill_nav.dart';
import '../books/books_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../spinner/spinner_screen.dart';

/// Main tabs: 0 Books, 1 Leaderboard.
/// Profile and the spinner open as pushed routes.
class HomeShell extends StatefulWidget {
  const HomeShell({
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
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _spinButtonSize = 56.0;
  static const _spinGap = 8.0;
  int _index = 0;
  bool _hintChecked = false;
  bool _showSpinHint = false;
  Timer? _hintTimer;
  final _spinAnchor = LayerLink();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hintChecked) return;
    _hintChecked = true;
    final settings = SettingsScope.of(context);
    if (settings.spinHintSeen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      settings.markSpinHintSeen();
      setState(() => _showSpinHint = true);
      _hintTimer = Timer(const Duration(seconds: 6), _dismissSpinHint);
    });
  }

  void _dismissSpinHint() {
    _hintTimer?.cancel();
    if (_showSpinHint && mounted) setState(() => _showSpinHint = false);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _openSpinner() {
    _dismissSpinHint();
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SpinnerScreen(
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
    final strings = context.s;

    final padding = MediaQuery.paddingOf(context);
    final pillHeight = FloatingPillNav.heightOf(context);
    const spinSpace = _spinButtonSize + _spinGap;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _dismissSpinHint(),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            IndexedStack(
              index: _index,
              children: [
                BooksScreen(
                  progress: widget.progress,
                  account: widget.account,
                  cloud: widget.cloud,
                  quizRepo: widget.quizRepo,
                ),
                LeaderboardScreen(
                  progress: widget.progress,
                  account: widget.account,
                  cloud: widget.cloud,
                ),
              ],
            ),
            if (MediaQuery.viewInsetsOf(context).bottom == 0)
              Positioned(
                left: padding.left + 16,
                right: padding.right + 16,
                bottom: padding.bottom + 12,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final pillWidth = math.min(
                      FloatingPillNav.widthFor(2),
                      constraints.maxWidth - spinSpace,
                    );
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1, end: _index == 0 ? 1 : 0),
                            duration: duration,
                            curve: Curves.easeInOut,
                            builder: (context, visibility, _) => SizedBox(
                              key: const ValueKey('home-navigation-row'),
                              width: pillWidth + spinSpace * visibility,
                              height: pillHeight,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  SizedBox(
                                    width: pillWidth,
                                    child: FloatingPillNav(
                                      selectedIndex: _index,
                                      onDestinationSelected: (i) {
                                        _dismissSpinHint();
                                        setState(() => _index = i);
                                      },
                                      destinations: [
                                        FloatingPillDestination(
                                          icon: Icons.menu_book_outlined,
                                          selectedIcon: Icons.menu_book,
                                          label: strings.navBooks,
                                        ),
                                        FloatingPillDestination(
                                          icon: Icons.emoji_events_outlined,
                                          selectedIcon: Icons.emoji_events,
                                          label: strings.navLeaderboard,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (visibility > 0)
                                    Positioned(
                                      left: pillWidth + _spinGap,
                                      top: (pillHeight - _spinButtonSize) / 2,
                                      child: _SpinButton(
                                        active: _index == 0,
                                        visibility: visibility,
                                        anchor: _spinAnchor,
                                        onPressed: _openSpinner,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            if (_showSpinHint &&
                _index == 0 &&
                MediaQuery.viewInsetsOf(context).bottom == 0)
              Positioned.fill(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: CompositedTransformFollower(
                        link: _spinAnchor,
                        showWhenUnlinked: false,
                        targetAnchor: Alignment.topRight,
                        followerAnchor: Alignment.bottomRight,
                        offset: const Offset(0, -8),
                        child: _SpinHint(
                          maxWidth: math.min(
                            272,
                            MediaQuery.sizeOf(context).width -
                                padding.horizontal -
                                32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpinButton extends StatelessWidget {
  const _SpinButton({
    required this.active,
    required this.visibility,
    required this.anchor,
    required this.onPressed,
  });
  final bool active;
  final double visibility;
  final LayerLink anchor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !active,
    child: ExcludeSemantics(
      excluding: !active,
      child: Opacity(
        opacity: visibility,
        child: Transform.scale(
          scale: visibility,
          child: CompositedTransformTarget(
            link: anchor,
            child: SizedBox.square(
              dimension: _HomeShellState._spinButtonSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: floatingControlShadows(context),
                ),
                child: FloatingActionButton(
                  key: const ValueKey('spin-fab'),
                  tooltip: context.s.spinReadingHint,
                  shape: const CircleBorder(),
                  elevation: 0,
                  focusElevation: 0,
                  hoverElevation: 0,
                  highlightElevation: 0,
                  onPressed: onPressed,
                  child: Semantics(
                    label: context.s.spinReadingHint,
                    child: const SpinWheelIcon(),
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

class _SpinHint extends StatelessWidget {
  const _SpinHint({required this.maxWidth});
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: maxWidth,
      child: Semantics(
        liveRegion: true,
        child: Material(
          key: const ValueKey('spin-fab-hint'),
          elevation: 2,
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              context.s.spinReadingHint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface),
            ),
          ),
        ),
      ),
    );
  }
}
