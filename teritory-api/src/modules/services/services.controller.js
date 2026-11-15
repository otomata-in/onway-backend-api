const prisma = require('../../config/prisma');
const ApiResponse = require('../../utils/ApiResponse');
const { haversineDistanceMeters } = require('../../utils/geo');

const getGearServices = async (req, res, next) => {
  try {
    const { lat, lng, category } = req.query;
    const centerLat = parseFloat(lat);
    const centerLng = parseFloat(lng);

    const where = {};
    if (category) {
      where.category = category;
    }

    const providers = await prisma.serviceProvider.findMany({
      where,
      include: {
        listings: { where: { isAvailable: true } },
      },
    });

    if (!isNaN(centerLat) && !isNaN(centerLng)) {
      const filtered = providers
        .map((p) => {
          const distanceM = haversineDistanceMeters(centerLat, centerLng, p.latitude, p.longitude);
          return {
            ...p,
            distanceKm: Math.round((distanceM / 1000) * 10) / 10,
          };
        })
        .sort((a, b) => a.distanceKm - b.distanceKm);

      return ApiResponse.success(res, filtered);
    }

    return ApiResponse.success(res, providers);
  } catch (err) {
    next(err);
  }
};

const getNearbyFood = async (req, res, next) => {
  try {
    const { lat, lng } = req.query;
    const centerLat = parseFloat(lat);
    const centerLng = parseFloat(lng);

    const foodProviders = await prisma.serviceProvider.findMany({
      where: {
        category: { contains: 'Food', mode: 'insensitive' },
      },
      include: {
        listings: true,
      },
    });

    if (!isNaN(centerLat) && !isNaN(centerLng)) {
      const filtered = foodProviders
        .map((p) => {
          const distanceM = haversineDistanceMeters(centerLat, centerLng, p.latitude, p.longitude);
          return {
            ...p,
            distanceKm: Math.round((distanceM / 1000) * 10) / 10,
          };
        })
        .filter((p) => p.distanceKm <= 10) // within 10km
        .sort((a, b) => a.distanceKm - b.distanceKm);

      return ApiResponse.success(res, filtered);
    }

    return ApiResponse.success(res, foodProviders);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getGearServices,
  getNearbyFood,
};

