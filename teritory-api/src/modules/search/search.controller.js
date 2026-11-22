const prisma = require('../../config/prisma');
const ApiResponse = require('../../utils/ApiResponse');

/**
 * Omni-Search across Flags (Major & Minor), Explorers (Users), Clans, and Place locations.
 */
const omniSearch = async (req, res, next) => {
  try {
    const { q = '', type = 'all' } = req.query;
    const query = (q || '').trim();
    const currentUserId = req.user?.id;

    if (!query) {
      // Suggestion payload: top major wonders and top clans
      const [topWonders, topClans] = await Promise.all([
        prisma.flag.findMany({
          where: { isMajorFlag: true },
          take: 6,
          orderBy: { kudos: 'desc' },
          include: {
            user: { select: { id: true, displayName: true, avatarUrl: true } },
          },
        }),
        prisma.clan.findMany({
          take: 5,
          orderBy: { memberCount: 'desc' },
          include: {
            chieftain: { select: { id: true, displayName: true, avatarUrl: true } },
            members: currentUserId
              ? { where: { userId: currentUserId }, select: { id: true } }
              : false,
          },
        }),
      ]);

      return ApiResponse.success(res, {
        flags: topWonders,
        users: [],
        clans: topClans.map((c) => ({
          ...c,
          isMember: currentUserId ? (c.members?.length > 0) : false,
        })),
        locations: [],
      });
    }

    const shouldSearchFlags = type === 'all' || type === 'flags' || type === 'places';
    const shouldSearchUsers = type === 'all' || type === 'users' || type === 'explorers';
    const shouldSearchClans = type === 'all' || type === 'clans';

    const [flags, users, clans] = await Promise.all([
      shouldSearchFlags
        ? prisma.flag.findMany({
            where: {
              OR: [
                { placeName: { contains: query, mode: 'insensitive' } },
                { city: { contains: query, mode: 'insensitive' } },
                { country: { contains: query, mode: 'insensitive' } },
                { notes: { contains: query, mode: 'insensitive' } },
              ],
            },
            include: {
              user: { select: { id: true, displayName: true, handle: true, avatarUrl: true } },
              _count: { select: { reactions: true, comments: true } },
            },
            take: 25,
            orderBy: [{ isMajorFlag: 'desc' }, { kudos: 'desc' }],
          })
        : [],
      shouldSearchUsers
        ? prisma.user.findMany({
            where: {
              OR: [
                { displayName: { contains: query, mode: 'insensitive' } },
                { handle: { contains: query, mode: 'insensitive' } },
              ],
            },
            select: {
              id: true,
              displayName: true,
              handle: true,
              avatarUrl: true,
              totalFlags: true,
              completedTripsCount: true,
              state: true,
              country: true,
            },
            take: 15,
          })
        : [],
      shouldSearchClans
        ? prisma.clan.findMany({
            where: {
              OR: [
                { name: { contains: query, mode: 'insensitive' } },
                { description: { contains: query, mode: 'insensitive' } },
                { interestTag: { contains: query, mode: 'insensitive' } },
                { region: { contains: query, mode: 'insensitive' } },
              ],
            },
            include: {
              chieftain: { select: { id: true, displayName: true, avatarUrl: true } },
              members: currentUserId
                ? { where: { userId: currentUserId }, select: { id: true } }
                : false,
            },
            take: 15,
          })
        : [],
    ]);

    // Extract unique locations/cities from matching flags
    const locationMap = new Map();
    for (const f of flags) {
      const key = `${(f.city || '').toLowerCase()}_${(f.country || '').toLowerCase()}`;
      if (!locationMap.has(key)) {
        locationMap.set(key, {
          city: f.city,
          country: f.country,
          latitude: f.latitude,
          longitude: f.longitude,
          flagCount: 1,
        });
      } else {
        locationMap.get(key).flagCount++;
      }
    }

    const formattedClans = clans.map((c) => ({
      ...c,
      isMember: currentUserId ? (c.members?.length > 0) : false,
    }));

    return ApiResponse.success(res, {
      flags,
      users,
      clans: formattedClans,
      locations: Array.from(locationMap.values()),
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  omniSearch,
};
