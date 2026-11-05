import 'dart:typed_data';

import 'package:bible_track/data/rank_system.dart';
import 'package:bible_track/data/settings_controller.dart';
import 'package:bible_track/features/rank/rank_badge.dart';
import 'package:bible_track/features/rank/rank_cards.dart';
import 'package:bible_track/l10n/strings.dart';
import 'package:bible_track/settings_scope.dart';
import 'package:bible_track/theme/app_theme.dart';
import 'package:bible_track/widgets/star_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late SettingsController settings;

  setUp(() async {
    settings = SettingsController(
      await Hive.openBox<dynamic>(
        'star_progress_settings',
        bytes: Uint8List(0),
      ),
    );
  });
  tearDown(() async {
    settings.dispose();
    await Hive.close();
  });

  for (final language in ['en', 'fil']) {
    for (final dark in [false, true]) {
      testWidgets('$language dark=$dark: every finite tier uses four stars', (
        tester,
      ) async {
        settings.setLanguage(language);
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final (stars, filled) in [
          (0, 0),
          (1, 1),
          (4, 4),
          (5, 1),
          (13, 1),
          (25, 1),
          (41, 1),
          (57, 1),
          (77, 1),
          (97, 1),
          (117, 1),
          (136, 4),
        ]) {
          await tester.pumpWidget(
            SettingsScope(
              controller: settings,
              child: MaterialApp(
                theme: dark ? darkTheme : lightTheme,
                home: Scaffold(body: CurrentRankCard(stars: stars)),
              ),
            ),
          );
          expect(find.byIcon(Icons.star_rounded), findsNWidgets(filled));
          expect(
            find.byIcon(Icons.star_outline_rounded),
            findsNWidgets(4 - filled),
          );
          expect(find.byType(LinearProgressIndicator), findsNothing);
          expect(
            find.text(Strings(language).rankName(rankForStars(stars))),
            findsOneWidget,
          );
          expect(find.byType(RankBadge), findsOneWidget);
          if (stars == 97) {
            expect(
              find.text(language == 'fil' ? 'Apostol V' : 'Apostle V'),
              findsOneWidget,
            );
            expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets('$language: top tier counts stars since entry', (tester) async {
      settings.setLanguage(language);
      for (final (stars, count) in [(137, 1), (1334, 1198)]) {
        await tester.pumpWidget(
          SettingsScope(
            controller: settings,
            child: MaterialApp(
              home: Scaffold(body: StarProgress(rank: rankForStars(stars))),
            ),
          ),
        );
        expect(find.text(Strings(language).rankStars(count)), findsOneWidget);
        expect(find.byType(Icon), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
      }
    });
  }
}
