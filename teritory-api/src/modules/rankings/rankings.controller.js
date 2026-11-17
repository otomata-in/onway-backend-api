const prisma = require('../../config/prisma');
const ApiResponse = require('../../utils/ApiResponse');
const ApiError = require('../../utils/ApiError');
const { calculateUserScore } = require('../../utils/scoring');

const PERIOD_DAYS = { WEEK: 7, MONTH: 30 };
const SCOPES = ['GLOBAL', 'COUNTRY', 'STATE', 'DISTRICT', 'FRIENDS', 'CLAN', 'COMMUNITY'];

/**
 * Aggregates the activity that happened inside the requested window, using the
 * same weights as calculateUserScore so a period ranking is comparable with the
 * all-time one.
 */
const buildPeriodStats = async (since) => {
  const [flags, tripEntries, rallyEntries, stamps] = await Promise.all([
    prisma.flag.findMany({
      where: { createdAt: { gte: since } },
      select: { userId: true, isMajorFlag: true, country: true, continent: true },
    }),
    prisma.tripParticipant.findMany({
      where: { trip: { status: 'COMPLETED', completedAt: { gte: since } } },
      select: { userId: true },
    }),
    prisma.rallyParticipant.findMany({
      where: { rally: { status: 'COMPLETED', completedAt: { gte: since } } },
      select: { userId: true },
    }),
    prisma.passportStamp.findMany({
      where: { createdAt: { gte: since } },
      select: { userId: true },
    }),
  ]);

  const stats = new Map();
  const entryFor = (userId) => {
    if (!stats.has(userId)) {
      stats.set(userId, {
        totalFlags: 0,
        majorFlags: 0,
        countries: new Set(),
        continents: new Set(),
        completedTripsCount: 0,
        legendaryRalliesCount: 0,
        stamps: 0,
      });
    }
    return stats.get(userId);
  };

  for (const flag of flags) {
    const entry = entryFor(flag.userId);
    entry.totalFlags += 1;
    if (flag.isMajorFlag) entry.majorFlags += 1;
    if (flag.country) entry.countries.add(flag.country);
    if (flag.continent) entry.continents.add(flag.continent);
  }
  for (const trip of tripEntries) entryFor(trip.userId).completedTripsCount += 1;
  for (const rally of rallyEntries) entryFor(rally.userId).legendaryRalliesCount += 1;
  for (const stamp of stamps) entryFor(stamp.userId).stamps += 1;

  return stats;
};

const scoreFromPeriodStats = (entry) =>
  entry.totalFlags * 10 +
  entry.majorFlags * 25 +
  entry.countries.size * 100 +
  entry.continents.size * 500 +
  entry.completedTripsCount * 50 +
  entry.legendaryRalliesCount * 200 +
  entry.stamps * 30;

const getLeaderboard = async (req, res, next) => {
  try {
    const {
      scope = 'GLOBAL',
      country,
      state,
      district,
      period = 'ALLTIME',
      page = 1,
      limit = 50,
    } = req.query;

    const normalizedScope = String(scope).toUpperCase();
    const normalizedPeriod = String(period).toUpperCase();

    if (!SCOPES.includes(normalizedScope)) {
      throw ApiError.badRequest(`Unsupported ranking scope: ${scope}`);
    }
    if (normalizedPeriod !== 'ALLTIME' && !PERIOD_DAYS[normalizedPeriod]) {
      throw ApiError.badRequest(`Unsupported ranking period: ${period}`);
    }

    const where = { isActive: true };
    const currentUserId = req.user?.id;

    if (normalizedScope === 'COUNTRY') {
      if (!country) throw ApiError.badRequest('A country is required for country rankings');
      where.country = country;
    } else if (normalizedScope === 'STATE') {
      if (!state) throw ApiError.badRequest('A state is required for state rankings');
      where.state = state;
    } else if (normalizedScope === 'DISTRICT') {
      if (!district) throw ApiError.badRequest('A district is required for district rankings');
      where.district = district;
    } else if (normalizedScope === 'FRIENDS') {
      if (!currentUserId) throw ApiError.unauthorized('Sign in to see friend rankings');
      const friendships = await prisma.friendRelationship.findMany({
        where: {
          status: 'ACCEPTED',
          OR: [{ senderId: currentUserId }, { receiverId: currentUserId }],
        },
      });

      const friendIds = friendships.map((f) => (f.senderId === currentUserId ? f.receiverId : f.senderId));
      friendIds.push(currentUserId);
      where.id = { in: friendIds };
    } else if (normalizedScope === 'CLAN') {
      if (!currentUserId) throw ApiError.unauthorized('Sign in to see clan rankings');
      const memberships = await prisma.clanMember.findMany({
        where: { userId: currentUserId },
        select: { clanId: true },
      });
      const clanIds = memberships.map((m) => m.clanId);
      if (clanIds.length === 0) {
        return ApiResponse.paginated(res, [], 0, page, limit);
      }
      const members = await prisma.clanMember.findMany({
        where: { clanId: { in: clanIds } },
        select: { userId: true },
      });
      where.id = { in: [...new Set(members.map((m) => m.userId))] };
    } else if (normalizedScope === 'COMMUNITY') {
      if (!currentUserId) throw ApiError.unauthorized('Sign in to see community rankings');
      const memberships = await prisma.communityMember.findMany({
        where: { userId: currentUserId },
        select: { communityId: true },
      });
      const communityIds = memberships.map((m) => m.communityId);
      if (communityIds.length === 0) {
        return ApiResponse.paginated(res, [], 0, page, limit);
      }
      const members = await prisma.communityMember.findMany({
        where: { communityId: { in: communityIds } },
        select: { userId: true },
      });
      where.id = { in: [...new Set(members.map((m) => m.userId))] };
    }

    const users = await prisma.user.findMany({
      where,
      include: { passportStamps: true },
    });

    const periodStart = PERIOD_DAYS[normalizedPeriod]
      ? new Date(Date.now() - PERIOD_DAYS[normalizedPeriod] * 24 * 60 * 60 * 1000)
      : null;
    const periodStats = periodStart ? await buildPeriodStats(periodStart) : null;

    // Score & sort users
    const scoredUsers = users
      .map((u) => {
        const windowed = periodStats?.get(u.id);
        if (periodStats && !windowed) return null;
        return {
          id: u.id,
          displayName: u.displayName,
          handle: u.handle,
          avatarUrl: u.avatarUrl,
          country: u.country,
          state: u.state,
          district: u.district,
          totalFlags: windowed ? windowed.totalFlags : u.totalFlags,
          majorFlags: windowed ? windowed.majorFlags : u.majorFlags,
          completedTripsCount: windowed
            ? windowed.completedTripsCount
            : u.completedTripsCount,
          score: windowed ? scoreFromPeriodStats(windowed) : calculateUserScore(u),
        };
      })
      .filter(Boolean)
      .sort((a, b) => b.score - a.score);

    // Assign ranks
    const rankedUsers = scoredUsers.map((u, idx) => ({
      ...u,
      rank: idx + 1,
    }));

    const startIndex = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const paginated = rankedUsers.slice(startIndex, startIndex + parseInt(limit, 10));

    return ApiResponse.paginated(res, paginated, rankedUsers.length, page, limit);
  } catch (err) {
    next(err);
  }
};

const getMyRank = async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      include: { passportStamps: true },
    });

    const myScore = calculateUserScore(user);

    // Count how many users have higher score in global
    const allUsers = await prisma.user.findMany({
      where: { isActive: true },
      include: { passportStamps: true },
    });

    const globalRank = allUsers.filter((u) => calculateUserScore(u) > myScore).length + 1;

    return ApiResponse.success(res, {
      score: myScore,
      globalRank,
      totalUsers: allUsers.length,
      breakdown: {
        flagsPoints: (user.totalFlags || 0) * 10,
        majorFlagsPoints: (user.majorFlags || 0) * 25,
        countriesPoints: (user.countriesVisited || 0) * 100,
        continentsPoints: (user.continentsVisited || 0) * 500,
        tripsPoints: (user.completedTripsCount || 0) * 50,
        ralliesPoints: (user.legendaryRalliesCount || 0) * 200,
        stampsPoints: (user.passportStamps?.length || 0) * 30,
      },
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getLeaderboard,
  getMyRank,
};

