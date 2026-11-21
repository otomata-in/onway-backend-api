/**
 * Geospatial calculation utilities
 */

/**
 * Calculates Haversine distance between two coordinates in meters
 */
function haversineDistanceMeters(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth's radius in meters
  const toRad = (deg) => (deg * Math.PI) / 180;

  const φ1 = toRad(lat1);
  const φ2 = toRad(lat2);
  const Δφ = toRad(lat2 - lat1);
  const Δλ = toRad(lon2 - lon1);

  const a =
    Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

/**
 * Calculates distance in kilometers
 */
function haversineDistanceKm(lat1, lon1, lat2, lon2) {
  return haversineDistanceMeters(lat1, lon1, lat2, lon2) / 1000;
}

/**
 * Check if coordinate is within radius
 */
function isWithinRadius(lat1, lon1, lat2, lon2, radiusMeters) {
  return haversineDistanceMeters(lat1, lon1, lat2, lon2) <= radiusMeters;
}

/**
 * Computes bounding box { minLat, maxLat, minLng, maxLng } for a given center and radius (km).
 * 1 degree latitude ~ 111 km.
 * 1 degree longitude ~ 111 km * cos(latitude).
 */
function getBoundingBox(centerLat, centerLng, radiusKm) {
  const safeRadius = Math.max(0.1, radiusKm || 50);
  const deltaLat = safeRadius / 111.0;
  const cosLat = Math.cos((centerLat * Math.PI) / 180);
  const deltaLng = safeRadius / (111.0 * Math.max(0.0001, Math.abs(cosLat)));

  return {
    minLat: Math.max(-90, centerLat - deltaLat),
    maxLat: Math.min(90, centerLat + deltaLat),
    minLng: Math.max(-180, centerLng - deltaLng),
    maxLng: Math.min(180, centerLng + deltaLng),
  };
}

module.exports = {
  haversineDistanceMeters,
  haversineDistanceKm,
  isWithinRadius,
  getBoundingBox,
};

