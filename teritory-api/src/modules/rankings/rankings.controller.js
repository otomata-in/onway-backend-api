const prisma = require('../../config/prisma');
const ApiResponse = require('../../utils/ApiResponse');
const { calculateUserScore } = require('../../utils/scoring');

const getLeaderboard = async (req, res, next) => {
  try {
    const { scope = 'GLOBAL', country, state, district, page = 1, limit = 50 } = req.query;

    const where = { isActive: true };
    const currentUserId = req.user?.id;

    if (scope === 'COUNTRY' && country) {
      where.country = country;
    } else if (scope === 'STATE' && state) {
      where.state = state;
    } else if (scope === 'DISTRICT' && district) {
      where.district = district;
    } else if (scope === 'FRIENDS' && currentUserId) {
      const friendships = await prisma.friendRelationship.findMany({
        where: {
          status: 'ACCEPTED',
          OR: [{ senderId: currentUserId }, { receiverId: currentUserId }],
        },
      });

      const friendIds = friendships.map((f) => (f.senderId === currentUserId ? f.receiverId : f.senderId));
      friendIds.push(currentUserId);
      where.id = { in: friendIds };
    }

    const users = await prisma.user.findMany({
      where,
      include: { passportStamps: true },
    });

    // Score & sort users
    const scoredUsers = users
      .map((u) => ({
        id: u.id,
        displayName: u.displayName,
        handle: u.handle,
        avatarUrl: u.avatarUrl,
        country: u.country,
        state: u.state,
        district: u.district,
        totalFlags: u.totalFlags,
        majorFlags: u.majorFlags,
        completedTripsCount: u.completedTripsCount,
        score: calculateUserScore(u),
      }))
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
