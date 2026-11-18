const prisma = require('../../config/prisma');
const ApiResponse = require('../../utils/ApiResponse');
const ApiError = require('../../utils/ApiError');
const { haversineDistanceMeters, haversineDistanceKm } = require('../../utils/geo');
const { notify } = require('../notifications/notifications.service');

// Major wonders registry — derived from the major flags travelers have staked.
// There is no official wonders table: one row per distinct place, with the
// claim count, the travelers who claimed it and whether the caller has.
const getWonders = async (req, res, next) => {
  try {
    const flags = await prisma.flag.findMany({
      where: { isMajorFlag: true },
      include: {
        user: {
          select: { id: true, displayName: true, handle: true, avatarUrl: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const currentUserId = req.user?.id;
    const byPlace = new Map();

    for (const flag of flags) {
      const key = `${flag.placeName.trim().toLowerCase()}|${(flag.country || '').trim().toLowerCase()}`;
      let wonder = byPlace.get(key);

      if (!wonder) {
        wonder = {
          key,
          placeName: flag.placeName,
          city: flag.city,
          country: flag.country,
          countryCode: flag.countryCode,
          continent: flag.continent,
          latitude: flag.latitude,
          longitude: flag.longitude,
          photoUrl: null,
          latestFlagId: flag.id,
          claimCount: 0,
          claimers: [],
          claimedByMe: false,
          lastClaimedAt: flag.createdAt,
        };
        byPlace.set(key, wonder);
      }

      wonder.claimCount += 1;
      if (!wonder.photoUrl && flag.photoUrl) wonder.photoUrl = flag.photoUrl;
      if (currentUserId && flag.userId === currentUserId) wonder.claimedByMe = true;
      if (!wonder.claimers.some((c) => c.id === flag.userId)) {
        wonder.claimers.push({
          id: flag.userId,
          displayName: flag.user?.displayName || 'Traveler',
          handle: flag.user?.handle || '',
          avatarUrl: flag.user?.avatarUrl || '',
        });
      }
    }

    const wonders = [...byPlace.values()].sort(
      (a, b) => b.claimCount - a.claimCount || a.placeName.localeCompare(b.placeName)
    );

    return ApiResponse.success(res, wonders);
  } catch (err) {
    next(err);
  }
};

// Explore nearby flags
const exploreFlags = async (req, res, next) => {
  try {
    const { lat, lng, radiusKm = 50, category, userId } = req.query;
    const centerLat = parseFloat(lat);
    const centerLng = parseFloat(lng);

    const where = {};
    if (category && category !== 'All') {
      where.category = category;
    }
    // Profile and friend-profile need one traveler's footprint, not a radius.
    if (userId) {
      where.userId = userId;
    }

    const allFlags = await prisma.flag.findMany({
      where,
      include: {
        user: {
          select: { id: true, displayName: true, handle: true, avatarUrl: true },
        },
        _count: {
          select: { reactions: true, comments: true },
        },
      },
    });

    // If center coordinates supplied, filter by radius
    if (!isNaN(centerLat) && !isNaN(centerLng)) {
      const radiusMeters = parseFloat(radiusKm) * 1000;
      const filtered = allFlags
        .map((f) => {
          const distanceM = haversineDistanceMeters(centerLat, centerLng, f.latitude, f.longitude);
          return { ...f, distanceKm: Math.round((distanceM / 1000) * 10) / 10 };
        })
        .filter((f) => f.distanceKm * 1000 <= radiusMeters)
        .sort((a, b) => a.distanceKm - b.distanceKm);

      return ApiResponse.success(res, filtered);
    }

    return ApiResponse.success(res, allFlags);
  } catch (err) {
    next(err);
  }
};

// Sub-territories / Hidden spots (<5km of famous spot)
const getSubTerritories = async (req, res, next) => {
  try {
    const { lat, lng } = req.query;
    const centerLat = parseFloat(lat);
    const centerLng = parseFloat(lng);

    if (isNaN(centerLat) || isNaN(centerLng)) {
      throw ApiError.badRequest('Latitude and longitude required');
    }

    const flags = await prisma.flag.findMany({
      where: {
        isMajorFlag: false,
      },
      include: {
        reactions: true,
        user: { select: { id: true, displayName: true, avatarUrl: true } },
      },
    });

    const subTerritories = flags
      .map((f) => {
        const distanceM = haversineDistanceMeters(centerLat, centerLng, f.latitude, f.longitude);
        const hiddenGemCount = f.reactions.filter((r) => r.type === 'HIDDEN_GEM').length;
        return {
          ...f,
          distanceM,
          distanceKm: Math.round((distanceM / 1000) * 10) / 10,
          hiddenGemCount,
        };
      })
      .filter((f) => f.distanceM <= 5000) // Within 5km
      .sort((a, b) => b.hiddenGemCount - a.hiddenGemCount || a.distanceM - b.distanceM);

    return ApiResponse.success(res, subTerritories);
  } catch (err) {
    next(err);
  }
};

// Drop Flag
const dropFlag = async (req, res, next) => {
  try {
    const {
      placeName,
      city,
      country = 'India',
      countryCode = 'IN',
      continent = 'Asia',
      latitude,
      longitude,
      isMajorFlag = false,
      category = 'General',
      notes = '',
      photoUrl,
    } = req.body;

    if (!placeName || latitude === undefined || longitude === undefined) {
      throw ApiError.badRequest('Place name, latitude and longitude are required');
    }

    const flag = await prisma.flag.create({
      data: {
        userId: req.user.id,
        placeName,
        city: city || '',
        country,
        countryCode,
        continent,
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        isMajorFlag: Boolean(isMajorFlag),
        category,
        notes,
        photoUrl,
      },
    });

    // Update user stats
    const userFlags = await prisma.flag.count({ where: { userId: req.user.id } });
    const majorCount = await prisma.flag.count({ where: { userId: req.user.id, isMajorFlag: true } });

    await prisma.user.update({
      where: { id: req.user.id },
      data: {
        totalFlags: userFlags,
        majorFlags: majorCount,
      },
    });

    // Award first flag stamp if milestone
    if (userFlags === 1) {
      await prisma.passportStamp.create({
        data: {
          userId: req.user.id,
          title: 'First Flag Dropped',
          category: 'Milestone',
          date: new Date().toLocaleDateString('en-US', { month: 'short', year: 'numeric' }),
          badgeColor: '#10B981',
          icon: 'flag',
        },
      });
    }

    return ApiResponse.created(res, flag, 'Flag dropped successfully!');
  } catch (err) {
    next(err);
  }
};

// Get single flag details
const getFlagById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const flag = await prisma.flag.findUnique({
      where: { id },
      include: {
        user: { select: { id: true, displayName: true, handle: true, avatarUrl: true } },
        reactions: true,
        comments: {
          include: {
            user: { select: { id: true, displayName: true, avatarUrl: true } },
          },
          orderBy: { createdAt: 'desc' },
          take: 20,
        },
      },
    });

    if (!flag) {
      throw ApiError.notFound('Flag not found');
    }

    let isSaved = false;
    if (req.user) {
      const saved = await prisma.$queryRaw`SELECT 1 FROM saved_flags WHERE user_id = ${req.user.id} AND flag_id = ${id} LIMIT 1`;
      isSaved = saved.length > 0;
    }

    return ApiResponse.success(res, { ...flag, isSaved });
  } catch (err) {
    next(err);
  }
};

// Toggle Save / Wishlist for a flag
const toggleSaveFlag = async (req, res, next) => {
  try {
    const { id: flagId } = req.params;
    const userId = req.user.id;

    const flag = await prisma.flag.findUnique({
      where: { id: flagId },
      select: { id: true, placeName: true },
    });
    if (!flag) throw ApiError.notFound('Flag not found');

    const existing = await prisma.$queryRaw`SELECT id FROM saved_flags WHERE user_id = ${userId} AND flag_id = ${flagId} LIMIT 1`;

    if (existing.length > 0) {
      await prisma.$executeRaw`DELETE FROM saved_flags WHERE user_id = ${userId} AND flag_id = ${flagId}`;
      return ApiResponse.success(res, { isSaved: false }, `Removed ${flag.placeName} from your wishlist`);
    } else {
      await prisma.$executeRaw`INSERT INTO saved_flags (user_id, flag_id) VALUES (${userId}, ${flagId}) ON CONFLICT DO NOTHING`;
      return ApiResponse.success(res, { isSaved: true }, `Saved ${flag.placeName} to your wishlist`);
    }
  } catch (err) {
    next(err);
  }
};

// Get Saved / Wishlist flags
const getSavedFlags = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const flags = await prisma.$queryRaw`
      SELECT f.id, f."placeName", f.latitude, f.longitude, f."isMajorFlag", f.category, f.notes, f."photoUrl", f.kudos, f."createdAt", sf.saved_at as "savedAt"
      FROM flags f
      JOIN saved_flags sf ON f.id = sf.flag_id
      WHERE sf.user_id = ${userId}
      ORDER BY sf.saved_at DESC
    `;
    return ApiResponse.success(res, flags);
  } catch (err) {
    next(err);
  }
};

// Toggle reaction
const toggleReaction = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { type } = req.body; // 'EPIC', 'HIDDEN_GEM', 'GREAT_SHOT'

    const existing = await prisma.flagReaction.findUnique({
      where: {
        flagId_userId_type: {
          flagId: id,
          userId: req.user.id,
          type,
        },
      },
    });

    if (existing) {
      await prisma.flagReaction.delete({
        where: { id: existing.id },
      });
      return ApiResponse.success(res, { reacted: false }, 'Reaction removed');
    } else {
      const reaction = await prisma.flagReaction.create({
        data: {
          flagId: id,
          userId: req.user.id,
          type,
        },
      });

      const flag = await prisma.flag.findUnique({
        where: { id },
        select: { userId: true, placeName: true },
      });
      if (flag && flag.userId !== req.user.id) {
        await notify({
          userId: flag.userId,
          type: 'SYSTEM',
          title: 'Reaction on your spot',
          body: `${req.user.displayName} reacted ${type} to "${flag.placeName}".`,
          icon: 'star',
          actionUrl: '/explore',
        });
      }

      return ApiResponse.created(res, { reacted: true, reaction }, 'Reaction added');
    }
  } catch (err) {
    next(err);
  }
};

// Add comment
const addComment = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { text } = req.body;

    if (!text || text.trim() === '') {
      throw ApiError.badRequest('Comment text cannot be empty');
    }

    const comment = await prisma.flagComment.create({
      data: {
        flagId: id,
        userId: req.user.id,
        text: text.trim(),
      },
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true } },
      },
    });

    const flag = await prisma.flag.findUnique({
      where: { id },
      select: { userId: true, placeName: true },
    });
    if (flag && flag.userId !== req.user.id) {
      const preview = text.trim().length > 40 ? `${text.trim().substring(0, 40)}…` : text.trim();
      await notify({
        userId: flag.userId,
        type: 'SYSTEM',
        title: 'New comment on your spot',
        body: `${req.user.displayName} commented on "${flag.placeName}": "${preview}"`,
        icon: 'chat',
        actionUrl: '/explore',
      });
    }

    return ApiResponse.created(res, comment, 'Comment posted');
  } catch (err) {
    next(err);
  }
};

// Increment kudos
const addKudos = async (req, res, next) => {
  try {
    const { id } = req.params;
    const updated = await prisma.flag.update({
      where: { id },
      data: { kudos: { increment: 1 } },
      select: { kudos: true, userId: true, placeName: true },
    });

    if (updated.userId !== req.user.id) {
      await notify({
        userId: updated.userId,
        type: 'SYSTEM',
        title: 'Kudos received!',
        body: `${req.user.displayName} gave kudos to your spot "${updated.placeName}".`,
        icon: 'heart',
        actionUrl: '/explore',
      });
    }

    return ApiResponse.success(res, { kudos: updated.kudos }, 'Kudos recorded');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getWonders,
  exploreFlags,
  getSubTerritories,
  dropFlag,
  getFlagById,
  toggleReaction,
  addComment,
  addKudos,
  toggleSaveFlag,
  getSavedFlags,
};

