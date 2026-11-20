const kStarsPerDivision = 4;

/// The single source of tier names and division counts. All thresholds are
/// derived from this list; zero divisions denotes the unlimited top tier.
const rankLadder = <RankTier>[
  RankTier('Seeker', 3),
  RankTier('Wanderer', 4),
  RankTier('Apprentice', 5),
  RankTier('Pathfinder', 6),
  RankTier('Mystic', 7),
  RankTier('Sage', 9),
  RankTier('Luminary', 0),
];

class RankTier {
  const RankTier(this.name, this.divisions);

  /// Tier names are English in both app languages.
  final String name;

  final int divisions;
}

enum RankDivision {
  ix('IX'),
  viii('VIII'),
  vii('VII'),
  vi('VI'),
  v('V'),
  iv('IV'),
  iii('III'),
  ii('II'),
  i('I');

  const RankDivision(this.numeral);
  final String numeral;
}

class RankInfo {
  const RankInfo({
    required this.tier,
    required this.division,
    required this.starsInDivision,
    this.topStars = 0,
  });

  final RankTier tier;
  final RankDivision? division;

  /// Filled slots in a finite division; zero in the unlimited top tier.
  final int starsInDivision;
  final int topStars;
  int get starsPerDivision => kStarsPerDivision;
  bool get isTopTier => division == null;

  bool isHigherThan(RankInfo other) {
    final tierIndex = rankLadder.indexOf(tier);
    final otherIndex = rankLadder.indexOf(other.tier);
    return tierIndex > otherIndex ||
        (tierIndex == otherIndex &&
            division != null &&
            other.division != null &&
            division!.index > other.division!.index);
  }
}

/// Stars are lifetime chapters. Negative input is treated as zero.
/// A full division keeps its four stars until the next chapter promotes it.
RankInfo rankForStars(int s) {
  final stars = s < 0 ? 0 : s;
  var divisionIndex = stars == 0 ? 0 : (stars - 1) ~/ kStarsPerDivision;
  var precedingDivisions = 0;
  for (final tier in rankLadder) {
    if (tier.divisions == 0) {
      return RankInfo(
        tier: tier,
        division: null,
        starsInDivision: 0,
        topStars: stars - precedingDivisions * kStarsPerDivision,
      );
    }
    if (divisionIndex < tier.divisions) {
      return RankInfo(
        tier: tier,
        division:
            RankDivision.values[RankDivision.values.length -
                tier.divisions +
                divisionIndex],
        starsInDivision: stars == 0 ? 0 : ((stars - 1) % kStarsPerDivision) + 1,
      );
    }
    divisionIndex -= tier.divisions;
    precedingDivisions += tier.divisions;
  }
  throw StateError('The rank ladder must end with an unlimited tier.');
}
