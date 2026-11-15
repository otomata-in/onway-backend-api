const prisma = require('../../config/prisma');
const ApiResponse = require('../../utils/ApiResponse');
const ApiError = require('../../utils/ApiError');
const { haversineDistanceMeters } = require('../../utils/geo');

const getTripsHub = async (req, res, next) => {
  try {
    const activeTrip = await prisma.trip.findFirst({
      where: {
        status: 'ACTIVE',
        participants: { some: { userId: req.user.id } },
      },
      include: {
        tripPlan: {
          include: { waypoints: { orderBy: { orderIndex: 'asc' } } },
        },
        participants: {
          include: { user: { select: { id: true, displayName: true, avatarUrl: true } } },
        },
      },
    });

    const proposedPlans = await prisma.tripPlan.findMany({
      where: { status: 'PROPOSED' },
      include: {
        waypoints: { orderBy: { orderIndex: 'asc' } },
        createdBy: { select: { id: true, displayName: true, avatarUrl: true } },
      },
      take: 10,
    });

    const savedPlans = await prisma.savedTripPlan.findMany({
      where: { userId: req.user.id },
      include: {
        tripPlan: {
          include: { waypoints: { orderBy: { orderIndex: 'asc' } } },
        },
      },
      take: 5,
    });

    return ApiResponse.success(res, {
      activeTrip,
      proposedPlans,
      savedPlans: savedPlans.map((s) => s.tripPlan),
    });
  } catch (err) {
    next(err);
  }
};

const createTripPlan = async (req, res, next) => {
  try {
    const {
      name,
      description = '',
      communityId,
      originName,
      destinationName,
      totalDistanceKm = 0.0,
      estimatedDays = 1,
      startDate,
      endDate,
      waypoints = [],
    } = req.body;

    if (!name || !originName || !destinationName) {
      throw ApiError.badRequest('Name, origin and destination required');
    }

    const plan = await prisma.tripPlan.create({
      data: {
        name,
        description,
        createdById: req.user.id,
        communityId,
        originName,
        destinationName,
        totalDistanceKm: parseFloat(totalDistanceKm),
        estimatedDays: parseInt(estimatedDays, 10),
        startDate: startDate ? new Date(startDate) : null,
        endDate: endDate ? new Date(endDate) : null,
        status: 'PROPOSED',
        waypoints: {
          create: waypoints.map((wp, index) => ({
            orderIndex: wp.orderIndex !== undefined ? wp.orderIndex : index,
            placeName: wp.placeName,
            latitude: parseFloat(wp.latitude),
            longitude: parseFloat(wp.longitude),
            category: wp.category || 'general',
            flagCount: wp.flagCount || 0,
            distanceFromPrevKm: parseFloat(wp.distanceFromPrevKm || 0.0),
          })),
        },
      },
      include: {
        waypoints: { orderBy: { orderIndex: 'asc' } },
      },
    });

    return ApiResponse.created(res, plan, 'Trip plan created');
  } catch (err) {
    next(err);
  }
};

const getTripPlanById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const plan = await prisma.tripPlan.findUnique({
      where: { id },
      include: {
        waypoints: { orderBy: { orderIndex: 'asc' } },
        createdBy: { select: { id: true, displayName: true, avatarUrl: true, handle: true } },
        votes: true,
      },
    });

    if (!plan) throw ApiError.notFound('Trip plan not found');

    const hasVoted = req.user ? plan.votes.some((v) => v.userId === req.user.id) : false;

    return ApiResponse.success(res, {
      ...plan,
      hasVoted,
    });
  } catch (err) {
    next(err);
  }
};

const voteTripPlan = async (req, res, next) => {
  try {
    const { id } = req.params;
    const existing = await prisma.tripVote.findUnique({
      where: { tripPlanId_userId: { tripPlanId: id, userId: req.user.id } },
    });

    if (existing) {
      await prisma.tripVote.delete({ where: { id: existing.id } });
      await prisma.tripPlan.update({ where: { id }, data: { voteCount: { decrement: 1 } } });
      return ApiResponse.success(res, { voted: false }, 'Vote removed');
    } else {
      await prisma.tripVote.create({
        data: { tripPlanId: id, userId: req.user.id },
      });
      await prisma.tripPlan.update({ where: { id }, data: { voteCount: { increment: 1 } } });
      return ApiResponse.created(res, { voted: true }, 'Vote recorded');
    }
  } catch (err) {
    next(err);
  }
};

const startTripFromPlan = async (req, res, next) => {
  try {
    const { id } = req.params;
    const plan = await prisma.tripPlan.findUnique({ where: { id } });
    if (!plan) throw ApiError.notFound('Trip plan not found');

    // Create Active Trip
    const expiresAt = new Date(Date.now() + 14 * 24 * 60 * 60 * 1000); // 14 days default
    const trip = await prisma.trip.create({
      data: {
        tripPlanId: id,
        createdById: req.user.id,
        status: 'ACTIVE',
        expiresAt,
        participants: {
          create: {
            userId: req.user.id,
            status: 'IN_PROGRESS',
          },
        },
      },
      include: {
        tripPlan: { include: { waypoints: { orderBy: { orderIndex: 'asc' } } } },
        participants: true,
      },
    });

    // Update user mode
    await prisma.user.update({
      where: { id: req.user.id },
      data: { isTripMode: true },
    });

    await prisma.tripPlan.update({
      where: { id },
      data: { status: 'ACTIVE' },
    });

    return ApiResponse.created(res, trip, 'Trip started! Expedition mode is active.');
  } catch (err) {
    next(err);
  }
};

const getTripById = async (req, res, next) => {
  try {
    const { tripId } = req.params;
    const trip = await prisma.trip.findUnique({
      where: { id: tripId },
      include: {
        tripPlan: { include: { waypoints: { orderBy: { orderIndex: 'asc' } } } },
        leader: { select: { id: true, displayName: true, avatarUrl: true } },
        participants: {
          include: { user: { select: { id: true, displayName: true, avatarUrl: true } } },
        },
        validations: {
          where: { userId: req.user.id },
        },
      },
    });

    if (!trip) throw ApiError.notFound('Trip not found');

    return ApiResponse.success(res, trip);
  } catch (err) {
    next(err);
  }
};

const joinActiveTrip = async (req, res, next) => {
  try {
    const { tripId } = req.params;
    const existing = await prisma.tripParticipant.findUnique({
      where: { tripId_userId: { tripId, userId: req.user.id } },
    });

    if (existing) throw ApiError.badRequest('Already participating in this trip');

    const participant = await prisma.tripParticipant.create({
      data: {
        tripId,
        userId: req.user.id,
        status: 'IN_PROGRESS',
      },
    });

    await prisma.user.update({
      where: { id: req.user.id },
      data: { isTripMode: true },
    });

    return ApiResponse.created(res, participant, 'Joined trip expedition');
  } catch (err) {
    next(err);
  }
};

// 15 km GPS Waypoint Validation
const validateWaypoint = async (req, res, next) => {
  try {
    const { tripId } = req.params;
    const { waypointId, latitude, longitude } = req.body;

    const userLat = parseFloat(latitude);
    const userLng = parseFloat(longitude);

    if (isNaN(userLat) || isNaN(userLng) || !waypointId) {
      throw ApiError.badRequest('Waypoint ID, user latitude and longitude are required');
    }

    const waypoint = await prisma.tripWaypoint.findUnique({
      where: { id: waypointId },
    });

    if (!waypoint) throw ApiError.notFound('Waypoint not found');

    const distanceM = haversineDistanceMeters(userLat, userLng, waypoint.latitude, waypoint.longitude);
    const MAX_ALLOWED_METERS = parseInt(process.env.WAYPOINT_VALIDATION_RADIUS_METERS || '15000', 10);

    const isValid = distanceM <= MAX_ALLOWED_METERS;

    const validation = await prisma.waypointValidation.upsert({
      where: {
        tripId_waypointId_userId: {
          tripId,
          waypointId,
          userId: req.user.id,
        },
      },
      create: {
        tripId,
        waypointId,
        userId: req.user.id,
        latitude: userLat,
        longitude: userLng,
        distanceM,
        isValid,
      },
      update: {
        latitude: userLat,
        longitude: userLng,
        distanceM,
        isValid,
        validatedAt: new Date(),
      },
    });

    return ApiResponse.success(res, {
      isValid,
      distanceM: Math.round(distanceM),
      maxAllowedMeters: MAX_ALLOWED_METERS,
      waypointName: waypoint.placeName,
      validation,
      message: isValid
        ? `Validated! You are within ${Math.round(distanceM / 1000)}km of ${waypoint.placeName}`
        : `Too far! You are ${Math.round(distanceM / 1000)}km away. Must be within 15km.`,
    });
  } catch (err) {
    next(err);
  }
};

const completeTrip = async (req, res, next) => {
  try {
    const { tripId } = req.params;
    const trip = await prisma.trip.findUnique({
      where: { id: tripId },
      include: {
        tripPlan: { include: { waypoints: true } },
        participants: true,
      },
    });

    if (!trip) throw ApiError.notFound('Trip not found');

    const totalWaypointsCount = trip.tripPlan.waypoints.length;

    // Evaluate each participant's validations
    for (const p of trip.participants) {
      const validCount = await prisma.waypointValidation.count({
        where: { tripId, userId: p.userId, isValid: true },
      });

      let badge = 'NONE';
      let status = 'DROPPED';

      if (validCount === totalWaypointsCount && totalWaypointsCount > 0) {
        badge = 'FULL';
        status = 'COMPLETED';
      } else if (validCount > 0) {
        badge = 'PARTIAL';
        status = 'COMPLETED';
      }

      await prisma.tripParticipant.update({
        where: { id: p.id },
        data: { badge, status },
      });

      if (status === 'COMPLETED') {
        await prisma.user.update({
          where: { id: p.userId },
          data: {
            completedTripsCount: { increment: 1 },
            isTripMode: false,
          },
        });
      } else {
        await prisma.user.update({
          where: { id: p.userId },
          data: { isTripMode: false },
        });
      }
    }

    const updated = await prisma.trip.update({
      where: { id: tripId },
      data: { status: 'COMPLETED', completedAt: new Date() },
      include: { participants: true },
    });

    return ApiResponse.success(res, updated, 'Trip marked completed!');
  } catch (err) {
    next(err);
  }
};

const getTripHistory = async (req, res, next) => {
  try {
    const participations = await prisma.tripParticipant.findMany({
      where: {
        userId: req.user.id,
        status: 'COMPLETED',
      },
      include: {
        trip: {
          include: {
            tripPlan: { include: { waypoints: { orderBy: { orderIndex: 'asc' } } } },
          },
        },
      },
      orderBy: { joinedAt: 'desc' },
    });

    const history = participations.map((p) => ({
      ...p.trip,
      myBadge: p.badge,
      completedAt: p.trip.completedAt,
    }));

    return ApiResponse.success(res, history);
  } catch (err) {
    next(err);
  }
};

const toggleSaveTripPlan = async (req, res, next) => {
  try {
    const { id: tripPlanId } = req.params;
    const userId = req.user.id;

    const plan = await prisma.tripPlan.findUnique({
      where: { id: tripPlanId },
    });
    if (!plan) {
      throw ApiError.notFound('Trip plan not found');
    }

    const existing = await prisma.savedTripPlan.findUnique({
      where: {
        userId_tripPlanId: { userId, tripPlanId },
      },
    });

    if (existing) {
      await prisma.savedTripPlan.delete({
        where: { id: existing.id },
      });
      return ApiResponse.success(res, { isSaved: false }, 'Trip plan removed from saved');
    } else {
      await prisma.savedTripPlan.create({
        data: { userId, tripPlanId },
      });
      return ApiResponse.success(res, { isSaved: true }, 'Trip plan saved');
    }
  } catch (err) {
    next(err);
  }
};

const getSavedTripPlans = async (req, res, next) => {
  try {
    const saved = await prisma.savedTripPlan.findMany({
      where: { userId: req.user.id },
      include: {
        tripPlan: {
          include: {
            waypoints: { orderBy: { orderIndex: 'asc' } },
            createdBy: { select: { id: true, displayName: true, avatarUrl: true } },
          },
        },
      },
      orderBy: { savedAt: 'desc' },
    });

    return ApiResponse.success(res, saved.map((s) => s.tripPlan));
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getTripsHub,
  createTripPlan,
  getTripPlanById,
  voteTripPlan,
  startTripFromPlan,
  getTripById,
  joinActiveTrip,
  validateWaypoint,
  completeTrip,
  getTripHistory,
  toggleSaveTripPlan,
  getSavedTripPlans,
};

