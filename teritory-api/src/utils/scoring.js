/**
 * Teritory prestige scoring formula
 */
function calculateUserScore(user) {
  const flags = (user.totalFlags || 0) * 10;
  const majorFlags = (user.majorFlags || 0) * 25;
  const countries = (user.countriesVisited || 0) * 100;
  const continents = (user.continentsVisited || 0) * 500;
  const trips = (user.completedTripsCount || 0) * 50;
  const rallies = (user.legendaryRalliesCount || 0) * 200;
  const stamps = (user.passportStamps?.length || 0) * 30;

  return flags + majorFlags + countries + continents + trips + rallies + stamps;
}

module.exports = {
  calculateUserScore,
};

