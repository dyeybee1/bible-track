import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/account_controller.dart';
import '../../data/cloud_repository.dart';
import '../../data/progress_controller.dart';
import '../../data/quiz_repository.dart';
import '../../settings_scope.dart';
import '../../widgets/spin_wheel_icon.dart';
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
  int _index = 0;
  bool _hintChecked = false;
  bool _showSpinHint = false;
  Timer? _hintTimer;

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

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _dismissSpinHint(),
      child: Scaffold(
        body: IndexedStack(
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
        floatingActionButton: _index == 0
            ? SizedBox(
                width: _showSpinHint
                    ? math.min(
                        320,
                        MediaQuery.sizeOf(context).width -
                            MediaQuery.paddingOf(context).horizontal -
                            32,
                      )
                    : 56,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_showSpinHint) ...[
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: Material(
                            key: const ValueKey('spin-fab-hint'),
                            elevation: 2,
                            color: Theme.of(context).colorScheme.inverseSurface,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                strings.spinReadingHint,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onInverseSurface,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    SizedBox.square(
                      dimension: 56,
                      child: FloatingActionButton(
                        key: const ValueKey('spin-fab'),
                        tooltip: strings.spinReadingHint,
                        onPressed: _openSpinner,
                        child: Semantics(
                          label: strings.spinReadingHint,
                          child: const SpinWheelIcon(),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: NavigationBar(
            animationDuration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book),
                label: strings.navBooks,
              ),
              NavigationDestination(
                icon: const Icon(Icons.emoji_events_outlined),
                selectedIcon: const Icon(Icons.emoji_events),
                label: strings.navLeaderboard,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
