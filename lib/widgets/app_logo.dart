import 'package:flutter/material.dart';

/// The real app icon, clipped with rounded corners.
/// The image already has its own white background, so no tinting is needed
/// in dark mode.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22;
    // Use a fixed pixel hint (300) rather than calling MediaQuery here to avoid
    // triggering extra rebuilds in tests or during the first frame.
    final cacheSize = (size * 3).clamp(128.0, 512.0).toInt();
    return Semantics(
      label: 'Bible Track',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/icon/bible-track-icon-1024.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: cacheSize,
          errorBuilder: (_, __, ___) => SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Icon(
                Icons.menu_book,
                size: size * 0.54,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
