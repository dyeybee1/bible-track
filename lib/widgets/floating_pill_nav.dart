import 'package:flutter/material.dart';

import '../settings_scope.dart';

/// Clearance for content that scrolls behind the home navigation controls.
double floatingNavContentPadding(BuildContext context) =>
    96 + MediaQuery.paddingOf(context).bottom;

class FloatingPillDestination {
  const FloatingPillDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
}

/// A compact navigation surface; add destinations without changing its layout.
class FloatingPillNav extends StatelessWidget {
  const FloatingPillNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : assert(destinations.length >= 2),
       assert(selectedIndex >= 0 && selectedIndex < destinations.length);

  static const height = 52.0;
  final List<FloatingPillDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    final showLabels = MediaQuery.textScalerOf(context).scale(11.5) <= 23;
    return Material(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: scheme.shadow.withValues(alpha: .16),
      shape: StadiumBorder(
        side: BorderSide(color: scheme.outlineVariant, width: .75),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final items = Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Expanded(
                      child: Semantics(
                        key: ValueKey('floating-nav-item-$i'),
                        container: true,
                        button: true,
                        selected: i == selectedIndex,
                        onTap: () => onDestinationSelected(i),
                        label: context.s.navTabSemantics(
                          destinations[i].label,
                          i + 1,
                          destinations.length,
                        ),
                        child: ExcludeSemantics(
                          child: InkWell(
                            onTap: () => onDestinationSelected(i),
                            borderRadius: BorderRadius.circular(height),
                            focusColor: scheme.primary.withValues(alpha: .15),
                            child: SizedBox(
                              height: height,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    key: ValueKey('floating-nav-indicator-$i'),
                                    duration: duration,
                                    curve: Curves.easeInOut,
                                    width: 48,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: i == selectedIndex
                                          ? scheme.primaryContainer
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Icon(
                                      i == selectedIndex
                                          ? destinations[i].selectedIcon ??
                                                destinations[i].icon
                                          : destinations[i].icon,
                                      size: 20,
                                      color: i == selectedIndex
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (showLabels) ...[
                                    const SizedBox(height: 2),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: SizedBox(
                                        height: 14,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            destinations[i].label,
                                            maxLines: 1,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  fontSize: 11.5,
                                                  height: 1.2,
                                                  color: i == selectedIndex
                                                      ? scheme.primary
                                                      : scheme.onSurfaceVariant,
                                                  fontWeight: i == selectedIndex
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
              final minimumWidth = destinations.length * 48.0;
              if (constraints.maxWidth < minimumWidth) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: minimumWidth, child: items),
                );
              }
              return items;
            },
          ),
        ),
      ),
    );
  }
}
