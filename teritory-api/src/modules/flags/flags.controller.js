const prisma = require('../../config/prisma');
const ApiResponse = require('../../utils/ApiResponse');
const ApiError = require('../../utils/ApiError');
const { haversineDistanceMeters, haversineDistanceKm, getBoundingBox } = require('../../utils/geo');
const { notify } = require('../notifications/notifications.service');
const { normalizeFlagStyle } = require('./flag_style');

// Major wonders registry — derived from the major flags travelers have staked.
// There is no official wonders table: one row per distinct place, with the
// claim count, the travelers who claimed it and whether the caller has.
const getWonders = async (req, res, next) => {
  try {
    const flags = await prisma.flag.findMany({
      where: { isMajorFlag: true, isHidden: false },
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
    const { lat, lng, radiusKm = 50, category, userId, includeHidden } = req.query;
    const centerLat = parseFloat(lat);
    const centerLng = parseFloat(lng);

    const where = {};
    const canSeeHidden =
      (includeHidden === 'true' || includeHidden === true) &&
      req.user?.id &&
      userId &&
      req.user.id === userId;
    if (!canSeeHidden) {
      where.isHidden = false;
    }
    if (category && category !== 'All') {
      where.category = category;
    }
    // Profile and friend-profile need one traveler's footprint, not a radius.
    if (userId) {
      where.userId = userId;
    }

    // High performance SQL bounding box filter using @@index([latitude, longitude])
    if (!isNaN(centerLat) && !isNaN(centerLng)) {
      const radius = parseFloat(radiusKm) || 50;
      const box = getBoundingBox(centerLat, centerLng, radius);
      where.latitude = { gte: box.minLat, lte: box.maxLat };
      where.longitude = { gte: box.minLng, lte: box.maxLng };
    }

    const flags = await prisma.flag.findMany({
      where,
      include: {
        user: {
          select: { id: true, displayName: true, handle: true, avatarUrl: true, flagStyle: true },
        },
        _count: {
          select: { reactions: true, comments: true },
        },
      },
    });

    // If center coordinates supplied, refine with exact Haversine distance and sort
    if (!isNaN(centerLat) && !isNaN(centerLng)) {
      const radiusMeters = (parseFloat(radiusKm) || 50) * 1000;
      const filtered = flags
        .map((f) => {
          const distanceM = haversineDistanceMeters(centerLat, centerLng, f.latitude, f.longitude);
          return { ...f, distanceKm: Math.round((distanceM / 1000) * 10) / 10 };
        })
        .filter((f) => f.distanceKm * 1000 <= radiusMeters)
        .sort((a, b) => a.distanceKm - b.distanceKm);

      return ApiResponse.success(res, filtered);
    }

    return ApiResponse.success(res, flags);
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

    const radiusMeters = parseInt(process.env.SUB_TERITORY_RADIUS_METERS, 10) || 5000;
    const radiusKm = radiusMeters / 1000;
    const box = getBoundingBox(centerLat, centerLng, radiusKm);

    const flags = await prisma.flag.findMany({
      where: {
        isMajorFlag: false,
        isHidden: false,
        latitude: { gte: box.minLat, lte: box.maxLat },
        longitude: { gte: box.minLng, lte: box.maxLng },
      },
      include: {
        reactions: true,
        user: { select: { id: true, displayName: true, avatarUrl: true, flagStyle: true } },
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
const MAX_FLAGS_PER_HOUR = 30;
const DUPLICATE_FLAG_RADIUS_METERS = 25;

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
      flagStyle: rawFlagStyle,
    } = req.body;

    const name = typeof placeName === 'string' ? placeName.trim() : '';
    if (!name || name.length > 120) {
      throw ApiError.badRequest('Place name is required (max 120 characters)');
    }

    const lat = Number(latitude);
    const lng = Number(longitude);
    if (
      !Number.isFinite(lat) ||
      !Number.isFinite(lng) ||
      Math.abs(lat) > 90 ||
      Math.abs(lng) > 180
    ) {
      throw ApiError.badRequest('Latitude and longitude must be valid coordinates');
    }

    // A flag carries ranking points, stamps and territory, so it must not be
    // possible to farm them with a script: one flag per spot, a modest rate, and
    // only real coordinates.
    const hourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const flagsLastHour = await prisma.flag.count({
      where: { userId: req.user.id, createdAt: { gte: hourAgo } },
    });
    if (flagsLastHour >= MAX_FLAGS_PER_HOUR) {
      throw ApiError.tooManyRequests(
        `You can stake at most ${MAX_FLAGS_PER_HOUR} flags an hour.`
      );
    }

    const box = getBoundingBox(lat, lng, 0.1);
    const nearby = await prisma.flag.findMany({
      where: {
        userId: req.user.id,
        latitude: { gte: box.minLat, lte: box.maxLat },
        longitude: { gte: box.minLng, lte: box.maxLng },
      },
      select: { placeName: true, latitude: true, longitude: true },
    });
    const duplicate = nearby.find(
      (f) =>
        haversineDistanceMeters(lat, lng, f.latitude, f.longitude) <=
        DUPLICATE_FLAG_RADIUS_METERS
    );
    if (duplicate) {
      throw ApiError.conflict(
        `You already staked this spot${duplicate.placeName ? ` ("${duplicate.placeName}")` : ''
        }.`
      );
    }

    // `Boolean('false')` is true, so parse the flag rather than trusting truthiness.
    const major = isMajorFlag === true || isMajorFlag === 'true';

    // Major Flag rule: a new Major Wonder suggestion is only allowed if it is
    // at least 5 km away from any existing Major Wonder, OR if this hidden spot
    // has already accumulated more than 50 flags.
    if (major) {
      const majorBox = getBoundingBox(lat, lng, 5.2);
      const candidateMajors = await prisma.flag.findMany({
        where: {
          isMajorFlag: true,
          latitude: { gte: majorBox.minLat, lte: majorBox.maxLat },
          longitude: { gte: majorBox.minLng, lte: majorBox.maxLng },
        },
        select: { id: true, placeName: true, latitude: true, longitude: true },
      });

      let nearestMajor = null;
      let nearestDist = Infinity;
      for (const m of candidateMajors) {
        const dist = haversineDistanceMeters(lat, lng, m.latitude, m.longitude);
        if (dist < 5000 && dist < nearestDist) {
          nearestDist = dist;
          nearestMajor = m;
        }
      }

      if (nearestMajor) {
        const spotBox = getBoundingBox(lat, lng, 0.2);
        const spotCandidates = await prisma.flag.findMany({
          where: {
            latitude: { gte: spotBox.minLat, lte: spotBox.maxLat },
            longitude: { gte: spotBox.minLng, lte: spotBox.maxLng },
          },
          select: { latitude: true, longitude: true },
        });
        const spotFlagCount = spotCandidates.filter(
          (f) => haversineDistanceMeters(lat, lng, f.latitude, f.longitude) <= 150
        ).length;

        if (spotFlagCount <= 50) {
          const distKm = (nearestDist / 1000).toFixed(1);
          throw ApiError.conflict(
            `Major Wonder "${nearestMajor.placeName}" is already ${distKm} km away. New Major Flag suggestions must be at least 5 km from existing Major Wonders (or reach 50+ flags at this spot). You can still stake a standard flag here.`
          );
        }
      }
    }

    // Validate explicit flagStyle if supplied, otherwise snapshot the user's
    // saved signature style so every staked flag reflects its creator.
    let resolvedFlagStyle = null;
    if (rawFlagStyle !== undefined && rawFlagStyle !== null) {
      resolvedFlagStyle = normalizeFlagStyle(rawFlagStyle);
    } else {
      const owner = await prisma.user.findUnique({
        where: { id: req.user.id },
        select: { flagStyle: true },
      });
      resolvedFlagStyle = owner?.flagStyle || null;
    }

    // Counts and the first-flag stamp move with the flag itself, in one batched
    // transaction, so a failure cannot leave a flag the profile does not count.
    const existingFlags = await prisma.flag.count({
      where: { userId: req.user.id },
    });
    const existingMajor = await prisma.flag.count({
      where: { userId: req.user.id, isMajorFlag: true },
    });
    const totalFlags = existingFlags + 1;
    const majorFlags = existingMajor + (major ? 1 : 0);

    const [flag] = await prisma.$transaction([
      prisma.flag.create({
        data: {
          userId: req.user.id,
          placeName: name,
          city: city || '',
          country,
          countryCode,
          continent,
          latitude: lat,
          longitude: lng,
          isMajorFlag: major,
          category,
          notes,
          photoUrl,
          ...(resolvedFlagStyle ? { flagStyle: resolvedFlagStyle } : {}),
        },
        include: {
          user: {
            select: { id: true, displayName: true, handle: true, avatarUrl: true, flagStyle: true },
          },
        },
      }),
      prisma.user.update({
        where: { id: req.user.id },
        data: { totalFlags, majorFlags },
      }),
      ...(totalFlags === 1
        ? [
          prisma.passportStamp.create({
            data: {
              userId: req.user.id,
              title: 'First Flag Dropped',
              category: 'Milestone',
              date: new Date().toLocaleDateString('en-US', {
                month: 'short',
                year: 'numeric',
              }),
              badgeColor: '#10B981',
              icon: 'flag',
            },
          }),
        ]
        : []),
    ]);

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
        user: { select: { id: true, displayName: true, handle: true, avatarUrl: true, flagStyle: true } },
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
      const saved = await prisma.savedFlag.findUnique({
        where: {
          userId_flagId: { userId: req.user.id, flagId: id },
        },
      });
      isSaved = !!saved;
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

    const existing = await prisma.savedFlag.findUnique({
      where: {
        userId_flagId: { userId, flagId },
      },
    });

    if (existing) {
      await prisma.savedFlag.delete({
        where: { id: existing.id },
      });
      return ApiResponse.success(res, { isSaved: false }, `Removed ${flag.placeName} from your wishlist`);
    } else {
      await prisma.savedFlag.create({
        data: { userId, flagId },
      });
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
    const saved = await prisma.savedFlag.findMany({
      where: { userId },
      include: {
        flag: {
          include: {
            user: {
              select: { id: true, displayName: true, handle: true, avatarUrl: true },
            },
            _count: {
              select: { reactions: true, comments: true },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    const flags = saved.map((s) => ({ ...s.flag, savedAt: s.createdAt }));
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

// Search flags across placeName, city, country, notes
const searchFlags = async (req, res, next) => {
  try {
    const { q = '', isMajorFlag } = req.query;
    if (!q.trim()) {
      return ApiResponse.success(res, []);
    }
    const query = q.trim();
    const where = {
      isHidden: false,
      OR: [
        { placeName: { contains: query, mode: 'insensitive' } },
        { city: { contains: query, mode: 'insensitive' } },
        { country: { contains: query, mode: 'insensitive' } },
        { notes: { contains: query, mode: 'insensitive' } },
      ],
    };
    if (isMajorFlag !== undefined) {
      where.isMajorFlag = isMajorFlag === 'true' || isMajorFlag === true;
    }

    const flags = await prisma.flag.findMany({
      where,
      include: {
        user: {
          select: { id: true, displayName: true, handle: true, avatarUrl: true, flagStyle: true },
        },
        _count: {
          select: { reactions: true, comments: true },
        },
      },
      take: 25,
      orderBy: [
        { isMajorFlag: 'desc' },
        { kudos: 'desc' },
      ],
    });

    return ApiResponse.success(res, flags);
  } catch (err) {
    next(err);
  }
};

// Update flag (Owner only: edit placeName, category, notes, photoUrl, or hide/show)
const updateFlag = async (req, res, next) => {
  try {
    const { id } = req.params;
    const existing = await prisma.flag.findUnique({
      where: { id },
      select: { id: true, userId: true },
    });

    if (!existing) {
      throw ApiError.notFound('Flag not found');
    }
    if (existing.userId !== req.user.id) {
      throw ApiError.forbidden('You can only manage flags staked by your account');
    }

    const { placeName, category, notes, photoUrl, isHidden } = req.body;
    const data = {};

    if (placeName !== undefined) {
      const trimmed = typeof placeName === 'string' ? placeName.trim() : '';
      if (!trimmed || trimmed.length > 120) {
        throw ApiError.badRequest('Place name is required (max 120 characters)');
      }
      data.placeName = trimmed;
    }
    if (category !== undefined && typeof category === 'string' && category.trim()) {
      data.category = category.trim();
    }
    if (notes !== undefined && typeof notes === 'string') {
      data.notes = notes.trim();
    }
    if (photoUrl !== undefined) {
      data.photoUrl = photoUrl ? String(photoUrl).trim() : null;
    }
    if (isHidden !== undefined) {
      data.isHidden = isHidden === true || isHidden === 'true';
    }

    const updated = await prisma.flag.update({
      where: { id },
      data,
      include: {
        user: {
          select: { id: true, displayName: true, handle: true, avatarUrl: true, flagStyle: true },
        },
        _count: {
          select: { reactions: true, comments: true },
        },
      },
    });

    return ApiResponse.success(res, updated, 'Flag updated successfully');
  } catch (err) {
    next(err);
  }
};

// Delete flag (Owner only, with relational cascade clean-up)
const deleteFlag = async (req, res, next) => {
  try {
    const { id } = req.params;
    const flag = await prisma.flag.findUnique({
      where: { id },
      select: { id: true, userId: true, placeName: true, isMajorFlag: true },
    });

    if (!flag) {
      throw ApiError.notFound('Flag not found');
    }

    if (flag.userId !== req.user.id) {
      throw ApiError.forbidden('You can only remove flags staked by your account');
    }

    await prisma.$transaction([
      prisma.flag.delete({
        where: { id },
      }),
      prisma.user.update({
        where: { id: req.user.id },
        data: {
          totalFlags: { decrement: 1 },
          ...(flag.isMajorFlag ? { majorFlags: { decrement: 1 } } : {}),
        },
      }),
    ]);

    return ApiResponse.success(res, { deleted: true, id }, `Flag "${flag.placeName}" has been removed`);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getWonders,
  exploreFlags,
  getSubTerritories,
  searchFlags,
  dropFlag,
  getFlagById,
  updateFlag,
  deleteFlag,
  toggleReaction,
  addComment,
  addKudos,
  toggleSaveFlag,
  getSavedFlags,
};

