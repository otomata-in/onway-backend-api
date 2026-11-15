const prisma = require('../../config/prisma');
const ApiResponse = require('../../utils/ApiResponse');
const ApiError = require('../../utils/ApiError');
const { haversineDistanceMeters, haversineDistanceKm } = require('../../utils/geo');

// Explore nearby flags
const exploreFlags = async (req, res, next) => {
  try {
    const { lat, lng, radiusKm = 50, category } = req.query;
    const centerLat = parseFloat(lat);
    const centerLng = parseFloat(lng);

    const where = {};
    if (category && category !== 'All') {
      where.category = category;
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

    return ApiResponse.success(res, flag);
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
    });
    return ApiResponse.success(res, { kudos: updated.kudos }, 'Kudos recorded');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  exploreFlags,
  getSubTerritories,
  dropFlag,
  getFlagById,
  toggleReaction,
  addComment,
  addKudos,
};

