import 'package:bible_track/data/rank_system.dart';
import 'package:bible_track/l10n/strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (stars, tier, division, inDivision, required) in [
    (0, 'Binhi', RankDivision.iii, 0, 10),
    (9, 'Binhi', RankDivision.iii, 9, 10),
    (10, 'Binhi', RankDivision.ii, 0, 10),
    (29, 'Binhi', RankDivision.i, 9, 10),
    (30, 'Usbong', RankDivision.iii, 0, 15),
    (74, 'Usbong', RankDivision.i, 14, 15),
    (75, 'Halaman', RankDivision.iii, 0, 25),
    (1079, 'Propeta', RankDivision.i, 119, 120),
    (1080, 'Salita ng Buhay', null, 0, 0),
    (1334, 'Salita ng Buhay', null, 254, 0),
    (1000000000000, 'Salita ng Buhay', null, 999999998920, 0),
  ]) {
    test('$stars stars: $tier $division', () {
      final rank = rankForStars(stars);
      expect(rank.tier.nameFil, tier);
      expect(rank.division, division);
      expect(rank.starsInDivision, inDivision);
      expect(rank.starsForDivision, required);
      expect(
        rank.starsNeededForNext,
        required == 0 ? 0 : required - inDivision,
      );
      expect(
        rank.progress,
        required == 0 ? 1.0 : closeTo(inDivision / required, 0.00001),
      );
    });
  }

  test(
    'every tier and division starts at the specified cumulative boundary',
    () {
      final starts = [0, 30, 75, 150, 270, 450, 720, 1080];
      final requirements = [10, 15, 25, 40, 60, 90, 120];
      for (var i = 0; i < requirements.length; i++) {
        for (var d = 0; d < 3; d++) {
          final start = starts[i] + d * requirements[i];
          final rank = rankForStars(start);
          expect(rank.tier, rankLadder[i]);
          expect(rank.division, RankDivision.values[d]);
          expect(rank.starsInDivision, 0);
          if (start > 0) {
            expect(rank.isHigherThan(rankForStars(start - 1)), isTrue);
            expect(rankForStars(start - 1).isHigherThan(rank), isFalse);
          }
        }
      }
      expect(rankForStars(1080).isHigherThan(rankForStars(1079)), isTrue);
      expect(rankForStars(1334).isHigherThan(rankForStars(1080)), isFalse);
      expect(rankForStars(9).isHigherThan(rankForStars(0)), isFalse);
    },
  );

  test('negative input is clamped to zero', () {
    final rank = rankForStars(-1);
    expect(rank.tier, rankLadder.first);
    expect(rank.starsInDivision, 0);
    expect(rank.progress, 0);
  });

  test('tier and division names are localized through Strings', () {
    const fil = Strings('fil');
    const en = Strings('en');
    expect(fil.rankName(rankForStars(190)), 'Puno II');
    expect(en.rankName(rankForStars(190)), 'Tree II');
    expect(fil.rankName(rankForStars(1080)), 'Salita ng Buhay');
    expect(en.rankName(rankForStars(1080)), 'Word of Life');
    for (final tier in rankLadder) {
      expect(fil.rankTierName(tier), isNotEmpty);
      expect(en.rankTierName(tier), isNotEmpty);
    }
  });
}
