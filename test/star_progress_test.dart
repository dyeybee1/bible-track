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

  for (final dark in [false, true]) {
    testWidgets('shield badges at 24, 40 and 96 pixels, dark=$dark', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      for (final stars in [0, 13, 29, 49, 73, 101, 137, 156, 186, 236]) {
        final rank = rankForStars(stars);
        final label = settings.strings.rankName(rank);
        for (final size in [24.0, 40.0, 96.0]) {
          await tester.pumpWidget(
            SettingsScope(
              controller: settings,
              child: MaterialApp(
                theme: dark ? darkTheme : lightTheme,
                home: Scaffold(
                  body: Center(
                    child: RankBadge(rank: rank, size: size),
                  ),
                ),
              ),
            ),
          );
          expect(tester.getSize(find.byType(RankBadge)), Size.square(size));
          expect(find.bySemanticsLabel(label), findsOneWidget);
          expect(
            tester.getSemantics(find.byType(RankBadge)),
            matchesSemantics(
              label: label,
              isImage: true,
              textDirection: TextDirection.ltr,
            ),
          );
          expect(tester.takeException(), isNull);
        }
      }
      semantics.dispose();
    });
  }

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
            expect(find.text('Mystic I'), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        }
      });
    }

    for (final dark in [false, true]) {
      testWidgets(
        '$language Luminary milestone progress at large text, dark=$dark',
        (tester) async {
          settings.setLanguage(language);
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          for (final total in [137, 162, 186, 236, 1334]) {
            await tester.pumpWidget(
              SettingsScope(
                controller: settings,
                child: MaterialApp(
                  theme: dark ? darkTheme : lightTheme,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(1.6)),
                    child: child!,
                  ),
                  home: Scaffold(body: CurrentRankCard(stars: total)),
                ),
              ),
            );
            final rank = rankForStars(total);
            expect(find.text(settings.strings.rankName(rank)), findsOneWidget);
            expect(
              find.text(settings.strings.rankStars(rank.topStars)),
              findsOneWidget,
            );
            final bar = find.byType(LinearProgressIndicator);
            expect(
              bar,
              rank.nextMilestone == null ? findsNothing : findsOneWidget,
            );
            if (rank.nextMilestone != null) {
              expect(
                tester.widget<LinearProgressIndicator>(bar).value,
                rank.milestoneProgress,
              );
              expect(
                find.text('${rank.topStars} / ${rank.nextMilestoneThreshold}'),
                findsOneWidget,
              );
            }
            expect(tester.takeException(), isNull);
          }
        },
      );
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
        expect(
          find.byType(LinearProgressIndicator),
          stars == 137 ? findsOneWidget : findsNothing,
        );
      }
    });
  }
}
