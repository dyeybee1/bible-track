import 'package:flutter/material.dart';

import '../../data/account_controller.dart';
import '../../data/cloud_repository.dart';
import '../../data/progress_controller.dart';
import '../../settings_scope.dart';
import '../books/books_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../spinner/spinner_screen.dart';

/// The main screen with the bottom navigation bar.
///
/// Tab order (index):
///   0 – Books    (Mga Libro / Books)
///   1 – Spin     (Paikot   / Spinner)
///   2 – Leaderboard (Ranggo / Leaderboard)  ← new
///   3 – Profile
///   4 – Settings
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.progress,
    required this.account,
    required this.cloud,
  });

  final ProgressController progress;
  final AccountController account;
  final CloudRepository cloud;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = context.s;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          // 0 – Books
          BooksScreen(
            progress: widget.progress,
            account: widget.account,
            cloud: widget.cloud,
          ),
          // 1 – Spin
          SpinnerScreen(
            progress: widget.progress,
            account: widget.account,
            cloud: widget.cloud,
          ),
          // 2 – Leaderboard
          LeaderboardScreen(
            progress: widget.progress,
            account: widget.account,
            cloud: widget.cloud,
          ),
          // 3 – Profile
          ProfileScreen(progress: widget.progress),
          // 4 – Settings
          SettingsScreen(account: widget.account),
        ],
      ),
      bottomNavigationBar: NavigationBar(
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
            icon: const Icon(Icons.casino_outlined),
            selectedIcon: const Icon(Icons.casino),
            label: strings.navSpin,
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon: const Icon(Icons.emoji_events),
            label: strings.navLeaderboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: strings.navProfile,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: strings.navSettings,
          ),
        ],
      ),
    );
  }
}
