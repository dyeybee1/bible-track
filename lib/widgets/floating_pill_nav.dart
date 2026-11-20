import 'package:flutter/material.dart';

import '../settings_scope.dart';
import '../theme/app_theme.dart';

/// Clearance for content that scrolls behind the home navigation controls.
double floatingNavContentPadding(BuildContext context) =>
    FloatingPillNav.heightOf(context) +
    28 +
    MediaQuery.paddingOf(context).bottom;

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

  static const height = 68.0;
  static const itemWidth = 94.0;
  static double widthFor(int count) => count * itemWidth + 12;

  static bool _showLabels(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(12) <= 24;

  /// Preserve the inner padding as labels grow with the user's text size.
  static double heightOf(BuildContext context) => _showLabels(context)
      ? 52 +
            MediaQuery.textScalerOf(
              context,
            ).scale(16).clamp(16, double.infinity)
      : height;
  final List<FloatingPillDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    final showLabels = _showLabels(context);
    final pillHeight = heightOf(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        shadows: floatingControlShadows(context),
      ),
      child: Material(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: widthFor(destinations.length),
          height: pillHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final items = Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < destinations.length; i++)
                      SizedBox(
                        width: itemWidth,
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
                              borderRadius: BorderRadius.circular(pillHeight),
                              focusColor: scheme.primary.withValues(alpha: .15),
                              child: SizedBox(
                                height: pillHeight,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedContainer(
                                        key: ValueKey(
                                          'floating-nav-indicator-$i',
                                        ),
                                        duration: duration,
                                        curve: Curves.easeInOut,
                                        width: 64,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: i == selectedIndex
                                              ? scheme.primaryContainer
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        child: Icon(
                                          i == selectedIndex
                                              ? destinations[i].selectedIcon ??
                                                    destinations[i].icon
                                              : destinations[i].icon,
                                          size: 24,
                                          color: i == selectedIndex
                                              ? scheme.primary
                                              : scheme.onSurfaceVariant,
                                        ),
                                      ),
                                      if (showLabels) ...[
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          child: SizedBox(
                                            height: MediaQuery.textScalerOf(
                                              context,
                                            ).scale(16),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                destinations[i].label,
                                                maxLines: 1,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      fontSize: 12,
                                                      height: 1.2,
                                                      color: i == selectedIndex
                                                          ? scheme.primary
                                                          : scheme
                                                                .onSurfaceVariant,
                                                      fontWeight:
                                                          i == selectedIndex
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
                      ),
                  ],
                );
                final minimumWidth = destinations.length * itemWidth;
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
      ),
    );
  }
}
