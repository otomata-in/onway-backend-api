const ApiResponse = require('../../utils/ApiResponse');
const ApiError = require('../../utils/ApiError');

const OSRM_BASE = 'https://router.project-osrm.org/route/v1/driving';

const getDirections = async (req, res, next) => {
  try {
    const { waypoints } = req.query;
    if (!waypoints) {
      throw ApiError.badRequest('waypoints query parameter is required (e.g. ?waypoints=lng1,lat1;lng2,lat2)');
    }

    const url = `${OSRM_BASE}/${encodeURI(waypoints)}?overview=full&geometries=geojson`;

    let osrmData;
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 10000);
      const response = await fetch(url, { signal: controller.signal });
      clearTimeout(timeout);
      osrmData = await response.json();
    } catch (_err) {
      return ApiResponse.success(res, {
        coordinates: [],
        distance_m: 0,
        duration_s: 0,
        fallback: true,
      });
    }

    if (osrmData.code !== 'Ok' || !osrmData.routes?.length) {
      return ApiResponse.success(res, {
        coordinates: [],
        distance_m: 0,
        duration_s: 0,
        fallback: true,
      });
    }

    const route = osrmData.routes[0];
    return ApiResponse.success(res, {
      coordinates: route.geometry.coordinates,
      distance_m: Math.round(route.distance),
      duration_s: Math.round(route.duration),
      fallback: false,
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { getDirections };
