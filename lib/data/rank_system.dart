/// The only source of tier names and star requirements. Starts are calculated
/// from the preceding tiers, so tuning a requirement updates the whole ladder.
const rankLadder = <RankTier>[
  RankTier('Binhi', 'Seed', 10),
  RankTier('Usbong', 'Sprout', 15),
  RankTier('Halaman', 'Plant', 25),
  RankTier('Puno', 'Tree', 40),
  RankTier('Ubasan', 'Vineyard', 60),
  RankTier('Alagad', 'Disciple', 90),
  RankTier('Propeta', 'Prophet', 120),
  RankTier('Salita ng Buhay', 'Word of Life', null),
];

class RankTier {
  const RankTier(this.nameFil, this.nameEn, this.starsPerDivision);

  final String nameFil;
  final String nameEn;

  /// null denotes the unlimited top tier.
  final int? starsPerDivision;
}

enum RankDivision { iii, ii, i }

class RankInfo {
  const RankInfo({
    required this.tier,
    required this.division,
    required this.starsInDivision,
    required this.starsForDivision,
    required this.starsNeededForNext,
    required this.progress,
  });

  final RankTier tier;
  final RankDivision? division;
  final int starsInDivision;

  /// Zero in the unlimited top tier, where there is no next division.
  final int starsForDivision;
  final int starsNeededForNext;
  final double progress;

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
/// In the top tier, starsInDivision counts stars since entering that tier,
/// progress is 1, and both starsForDivision and starsNeededForNext are zero.
RankInfo rankForStars(int stars) {
  var remaining = stars < 0 ? 0 : stars;
  for (final tier in rankLadder) {
    final required = tier.starsPerDivision;
    if (required == null) {
      return RankInfo(
        tier: tier,
        division: null,
        starsInDivision: remaining,
        starsForDivision: 0,
        starsNeededForNext: 0,
        progress: 1,
      );
    }
    final tierStars = required * RankDivision.values.length;
    if (remaining < tierStars) {
      final inDivision = remaining % required;
      return RankInfo(
        tier: tier,
        division: RankDivision.values[remaining ~/ required],
        starsInDivision: inDivision,
        starsForDivision: required,
        starsNeededForNext: required - inDivision,
        progress: inDivision / required,
      );
    }
    remaining -= tierStars;
  }
  throw StateError('The rank ladder must end with an unlimited tier.');
}
