import 'package:flutter/material.dart';

import 'bible_track_mark.dart';

/// The same brand mark used by the launcher, rendered sharply at any size.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22;
    return Semantics(
      label: 'Bible Track',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          size: Size.square(size),
          painter: const BibleTrackMark(),
        ),
      ),
    );
  }
}
