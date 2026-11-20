import 'package:bible_track/data/rank_system.dart';
import 'package:bible_track/l10n/strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cases = [
    (0, 'Seeker', RankDivision.iii, 0),
    (1, 'Seeker', RankDivision.iii, 1),
    (4, 'Seeker', RankDivision.iii, 4),
    (5, 'Seeker', RankDivision.ii, 1),
    (12, 'Seeker', RankDivision.i, 4),
    (13, 'Wanderer', RankDivision.iv, 1),
    (28, 'Wanderer', RankDivision.i, 4),
    (29, 'Apprentice', RankDivision.v, 1),
    (48, 'Apprentice', RankDivision.i, 4),
    (49, 'Pathfinder', RankDivision.vi, 1),
    (72, 'Pathfinder', RankDivision.i, 4),
    (73, 'Mystic', RankDivision.vii, 1),
    (100, 'Mystic', RankDivision.i, 4),
    (101, 'Sage', RankDivision.ix, 1),
    (136, 'Sage', RankDivision.i, 4),
    (137, 'Luminary', null, 1),
    (1334, 'Luminary', null, 1198),
    (1000000000000, 'Luminary', null, 999999999864),
  ];
  for (final (stars, tier, division, count) in cases) {
    test('$stars stars: $tier $division with $count stars', () {
      final rank = rankForStars(stars);
      expect(rank.tier.name, tier);
      expect(rank.division, division);
      expect(rank.starsPerDivision, 4);
      expect(rank.isTopTier, division == null);
      expect(rank.starsInDivision, division == null ? 0 : count);
      expect(rank.topStars, division == null ? count : 0);
    });
  }

  test('all 34 finite divisions keep four stars before promotion', () {
    expect(rankLadder.map((t) => t.divisions), [3, 4, 5, 6, 7, 9, 0]);
    for (var d = 1; d <= 34; d++) {
      final full = rankForStars(d * 4);
      final next = rankForStars(d * 4 + 1);
      expect(full.starsInDivision, 4);
      expect(next.isHigherThan(full), isTrue);
      expect(full.isHigherThan(next), isFalse);
      expect(next.isTopTier ? next.topStars : next.starsInDivision, 1);
    }
    expect(rankForStars(4).isHigherThan(rankForStars(0)), isFalse);
    expect(rankForStars(1334).isHigherThan(rankForStars(137)), isTrue);
    expect(rankForStars(5000).isHigherThan(rankForStars(1334)), isFalse);
  });

  test('unmark/mark restores every boundary and supplied example', () {
    Object snapshot(int s) {
      final r = rankForStars(s);
      return (
        r.tier,
        r.division,
        r.starsInDivision,
        r.starsPerDivision,
        r.topStars,
        r.isTopTier,
      );
    }

    final boundaries = {
      for (final (stars, _, _, _) in cases)
        if (stars > 0) stars,
      for (var d = 1; d <= 34; d++) d * 4 + 1,
    };
    for (final stars in boundaries) {
      var chapters = stars;
      final before = snapshot(chapters);
      chapters--;
      final lower = snapshot(chapters);
      chapters++;
      expect(snapshot(chapters), before);
      chapters--;
      expect(snapshot(chapters), lower);
    }
  });

  test('negative input is clamped to the initial rank', () {
    final rank = rankForStars(-1);
    expect(rank.tier, rankLadder.first);
    expect(rank.division, RankDivision.iii);
    expect(rank.starsInDivision, 0);
    expect(rank.topStars, 0);
    expect(rank.isTopTier, isFalse);
  });

  test('rank names are identical in both UI languages', () {
    const fil = Strings('fil');
    const en = Strings('en');
    for (final (stars, tier, division, _) in cases) {
      final expected = division == null
          ? (stars >= 236 ? '$tier Zenith' : tier)
          : '$tier ${division.numeral}';
      expect(fil.rankName(rankForStars(stars)), expected);
      expect(en.rankName(rankForStars(stars)), expected);
    }
    expect(en.rankName(rankForStars(49)), 'Pathfinder VI');
    expect(fil.rankName(rankForStars(101)), 'Sage IX');
    expect(fil.starRankUp('Pathfinder VI'), 'Umakyat ka sa Pathfinder VI!');
    expect(en.starRankDown('Wanderer I'), 'You moved down to Wanderer I');
  });

  test('Roman division numerals count down from IX to I', () {
    expect(
      RankDivision.values.map((d) => const Strings('fil').rankDivision(d)),
      ['IX', 'VIII', 'VII', 'VI', 'V', 'IV', 'III', 'II', 'I'],
    );
    for (var i = 0; i < 9; i++) {
      expect(rankForStars(101 + i * 4).division, RankDivision.values[i]);
    }
  });
  test('Luminary milestones, thresholds and progress use top-tier stars', () {
    const cases = [
      (137, null, 20, 'Luminary'),
      (155, null, 20, 'Luminary'),
      (156, 'Spark', 50, 'Luminary Spark'),
      (162, 'Spark', 50, 'Luminary Spark'),
      (185, 'Spark', 50, 'Luminary Spark'),
      (186, 'Beacon', 100, 'Luminary Beacon'),
      (235, 'Beacon', 100, 'Luminary Beacon'),
      (236, 'Zenith', null, 'Luminary Zenith'),
      (1334, 'Zenith', null, 'Luminary Zenith'),
      (1000000000000, 'Zenith', null, 'Luminary Zenith'),
    ];
    for (final (total, milestone, next, label) in cases) {
      final rank = rankForStars(total);
      expect(rank.milestone?.title, milestone);
      expect(rank.nextMilestoneThreshold, next);
      expect(rank.topStars, total - 136);
      expect(
        rank.milestoneProgress,
        next == null ? null : closeTo((total - 136) / next, .00001),
      );
      expect(const Strings('fil').rankName(rank), label);
      expect(const Strings('en').rankName(rank), label);
    }
    expect(rankForStars(136).milestone, isNull);
    expect(rankForStars(136).nextMilestoneThreshold, isNull);
    expect(rankForStars(136).milestoneProgress, isNull);
    for (final total in [156, 186, 236]) {
      expect(rankForStars(total).isHigherThan(rankForStars(total - 1)), isTrue);
      expect(
        rankForStars(total - 1).isHigherThan(rankForStars(total)),
        isFalse,
      );
    }
  });
}
