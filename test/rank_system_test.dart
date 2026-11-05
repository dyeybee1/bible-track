import 'package:bible_track/data/rank_system.dart';
import 'package:bible_track/l10n/strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cases = [
    (0, 'Binhi', RankDivision.iii, 0),
    (1, 'Binhi', RankDivision.iii, 1),
    (4, 'Binhi', RankDivision.iii, 4),
    (5, 'Binhi', RankDivision.ii, 1),
    (8, 'Binhi', RankDivision.ii, 4),
    (9, 'Binhi', RankDivision.i, 1),
    (12, 'Binhi', RankDivision.i, 4),
    (13, 'Usbong', RankDivision.iii, 1),
    (24, 'Usbong', RankDivision.i, 4),
    (25, 'Halaman', RankDivision.iv, 1),
    (40, 'Halaman', RankDivision.i, 4),
    (41, 'Puno', RankDivision.iv, 1),
    (56, 'Puno', RankDivision.i, 4),
    (57, 'Ubasan', RankDivision.v, 1),
    (76, 'Ubasan', RankDivision.i, 4),
    (77, 'Alagad', RankDivision.v, 1),
    (96, 'Alagad', RankDivision.i, 4),
    (97, 'Apostol', RankDivision.v, 1),
    (116, 'Apostol', RankDivision.i, 4),
    (117, 'Propeta', RankDivision.v, 1),
    (136, 'Propeta', RankDivision.i, 4),
    (137, 'Salita ng Buhay', null, 1),
    (1334, 'Salita ng Buhay', null, 1198),
    (1000000000000, 'Salita ng Buhay', null, 999999999864),
  ];
  for (final (stars, tier, division, count) in cases) {
    test('$stars stars: $tier $division with $count stars', () {
      final rank = rankForStars(stars);
      expect(rank.tier.nameFil, tier);
      expect(rank.division, division);
      expect(rank.starsPerDivision, 4);
      expect(rank.isTopTier, division == null);
      expect(rank.starsInDivision, division == null ? 0 : count);
      expect(rank.topStars, division == null ? count : 0);
    });
  }

  test('all 34 finite divisions keep four stars before promotion', () {
    expect(rankLadder.map((t) => t.divisions), [3, 3, 4, 4, 5, 5, 5, 5, 0]);
    for (var d = 1; d <= 34; d++) {
      final full = rankForStars(d * 4);
      final next = rankForStars(d * 4 + 1);
      expect(full.starsInDivision, 4);
      expect(next.isHigherThan(full), isTrue);
      expect(full.isHigherThan(next), isFalse);
      expect(next.isTopTier ? next.topStars : next.starsInDivision, 1);
    }
    expect(rankForStars(4).isHigherThan(rankForStars(0)), isFalse);
    expect(rankForStars(1334).isHigherThan(rankForStars(137)), isFalse);
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

  test('tier and division names are localized through Strings', () {
    const fil = Strings('fil');
    const en = Strings('en');
    expect(fil.rankName(rankForStars(25)), 'Halaman IV');
    expect(en.rankName(rankForStars(25)), 'Plant IV');
    expect(fil.rankName(rankForStars(57)), 'Ubasan V');
    expect(en.rankName(rankForStars(57)), 'Vineyard V');
    expect(fil.rankName(rankForStars(97)), 'Apostol V');
    expect(en.rankName(rankForStars(97)), 'Apostle V');
    expect(fil.rankName(rankForStars(137)), 'Salita ng Buhay');
    expect(en.rankName(rankForStars(137)), 'Word of Life');
    for (final tier in rankLadder) {
      expect(fil.rankTierName(tier), isNotEmpty);
      expect(en.rankTierName(tier), isNotEmpty);
    }
  });
}
