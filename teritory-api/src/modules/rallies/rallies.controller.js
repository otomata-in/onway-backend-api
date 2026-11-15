const prisma = require('../../config/prisma');
const ApiResponse = require('../../utils/ApiResponse');
const ApiError = require('../../utils/ApiError');
const { haversineDistanceMeters } = require('../../utils/geo');

const createRally = async (req, res, next) => {
  try {
    const { name, description = '', latitude, longitude, placeName, minParticipants = 3, maxParticipants = 50, expiresHours = 48 } = req.body;
    if (!name || latitude === undefined || longitude === undefined || !placeName) {
      throw ApiError.badRequest('Name, coordinates and place name required');
    }

    const expiresAt = new Date(Date.now() + parseInt(expiresHours, 10) * 60 * 60 * 1000);

    const rally = await prisma.legendaryRally.create({
      data: {
        name,
        description,
        createdById: req.user.id,
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        placeName,
        minParticipants: parseInt(minParticipants, 10),
        maxParticipants: parseInt(maxParticipants, 10),
        expiresAt,
        participants: {
          create: {
            userId: req.user.id,
            hasArrived: false,
          },
        },
      },
      include: {
        participants: { include: { user: { select: { id: true, displayName: true, avatarUrl: true } } } },
      },
    });

    return ApiResponse.created(res, rally, 'Legendary Rally initiated!');
  } catch (err) {
    next(err);
  }
};

const getNearbyRallies = async (req, res, next) => {
  try {
    const { lat, lng, radiusKm = 100 } = req.query;
    const centerLat = parseFloat(lat);
    const centerLng = parseFloat(lng);

    const rallies = await prisma.legendaryRally.findMany({
      where: { status: { in: ['GATHERING', 'ACTIVE'] } },
      include: {
        host: { select: { id: true, displayName: true, avatarUrl: true } },
        participants: { include: { user: { select: { id: true, displayName: true, avatarUrl: true } } } },
      },
    });

    if (!isNaN(centerLat) && !isNaN(centerLng)) {
      const radiusMeters = parseFloat(radiusKm) * 1000;
      const filtered = rallies
        .map((r) => {
          const distanceM = haversineDistanceMeters(centerLat, centerLng, r.latitude, r.longitude);
          return { ...r, distanceKm: Math.round((distanceM / 1000) * 10) / 10 };
        })
        .filter((r) => r.distanceKm * 1000 <= radiusMeters);

      return ApiResponse.success(res, filtered);
    }

    return ApiResponse.success(res, rallies);
  } catch (err) {
    next(err);
  }
};

const getRallyById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const rally = await prisma.legendaryRally.findUnique({
      where: { id },
      include: {
        host: { select: { id: true, displayName: true, avatarUrl: true } },
        participants: { include: { user: { select: { id: true, displayName: true, avatarUrl: true, handle: true } } } },
      },
    });

    if (!rally) throw ApiError.notFound('Rally not found');

    return ApiResponse.success(res, rally);
  } catch (err) {
    next(err);
  }
};

const joinRally = async (req, res, next) => {
  try {
    const { id } = req.params;
    const existing = await prisma.rallyParticipant.findUnique({
      where: { rallyId_userId: { rallyId: id, userId: req.user.id } },
    });

    if (existing) throw ApiError.badRequest('Already participating in this rally');

    const participant = await prisma.rallyParticipant.create({
      data: {
        rallyId: id,
        userId: req.user.id,
      },
    });

    return ApiResponse.created(res, participant, 'Joined Legendary Rally');
  } catch (err) {
    next(err);
  }
};

// GPS arrival check (≤500m of rally destination)
const markArrival = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { latitude, longitude } = req.body;

    const userLat = parseFloat(latitude);
    const userLng = parseFloat(longitude);

    const rally = await prisma.legendaryRally.findUnique({ where: { id } });
    if (!rally) throw ApiError.notFound('Rally not found');

    const distanceM = haversineDistanceMeters(userLat, userLng, rally.latitude, rally.longitude);
    const MAX_ARRIVAL_METERS = parseInt(process.env.RALLY_ARRIVAL_RADIUS_METERS || '500', 10);

    const isArrived = distanceM <= MAX_ARRIVAL_METERS;

    if (!isArrived) {
      return ApiResponse.success(res, {
        arrived: false,
        distanceM: Math.round(distanceM),
        message: `Too far! You are ${Math.round(distanceM)}m away. Must be within ${MAX_ARRIVAL_METERS}m to register arrival.`,
      });
    }

    const updated = await prisma.rallyParticipant.upsert({
      where: { rallyId_userId: { rallyId: id, userId: req.user.id } },
      create: { rallyId: id, userId: req.user.id, hasArrived: true, arrivedAt: new Date() },
      update: { hasArrived: true, arrivedAt: new Date() },
    });

    return ApiResponse.success(res, {
      arrived: true,
      distanceM: Math.round(distanceM),
      participant: updated,
      message: 'Arrival verified! You are at the rally location.',
    });
  } catch (err) {
    next(err);
  }
};

const completeRally = async (req, res, next) => {
  try {
    const { id } = req.params;
    const rally = await prisma.legendaryRally.findUnique({
      where: { id },
      include: { participants: true },
    });

    if (!rally) throw ApiError.notFound('Rally not found');
    if (rally.createdById !== req.user.id) {
      throw ApiError.forbidden('Only rally organizer can complete the rally');
    }

    const arrivedParticipants = rally.participants.filter((p) => p.hasArrived);
    if (arrivedParticipants.length < rally.minParticipants) {
      throw ApiError.badRequest(`Need at least ${rally.minParticipants} verified arrivals (Current: ${arrivedParticipants.length})`);
    }

    // Mark rally completed
    const updated = await prisma.legendaryRally.update({
      where: { id },
      data: { status: 'COMPLETED', completedAt: new Date() },
    });

    // Create collective Major Flag
    await prisma.flag.create({
      data: {
        userId: req.user.id,
        placeName: rally.placeName,
        city: 'Collective Rally',
        latitude: rally.latitude,
        longitude: rally.longitude,
        isMajorFlag: true,
        category: 'Legendary Rally',
        notes: `Historic collective flag dropped by ${arrivedParticipants.length} travelers in ${rally.name}!`,
      },
    });

    // Update stats for all arrived participants
    for (const p of arrivedParticipants) {
      await prisma.user.update({
        where: { id: p.userId },
        data: {
          legendaryRalliesCount: { increment: 1 },
          totalFlags: { increment: 1 },
        },
      });

      // Award Legendary Stamp
      await prisma.passportStamp.create({
        data: {
          userId: p.userId,
          title: `Rally: ${rally.name}`,
          category: 'Legendary Rally',
          date: new Date().toLocaleDateString('en-US', { month: 'short', year: 'numeric' }),
          badgeColor: '#F59E0B',
          icon: 'stars',
        },
      });
    }

    return ApiResponse.success(res, updated, 'Legendary Rally complete! Collective flag dropped.');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createRally,
  getNearbyRallies,
  getRallyById,
  joinRally,
  markArrival,
  completeRally,
};
