const { Vendor, User, Item, Favorite, VendorRoute, VendorRoutePoint, sequelize } = require('../../models');
const ApiError = require('../../utils/ApiError');
const redis = require('../../config/redis');
const { QueryTypes } = require('sequelize');

const vendorService = {
  /**
   * Find nearby active vendors
   * Uses Redis-cached locations when available, falls back to DB Haversine query
   *
   * @param {number} lat - Buyer's latitude
   * @param {number} lng - Buyer's longitude
   * @param {number} radius - Search radius in km (default 5)
   */
  async getNearby(lat, lng, radius = 5) {
    // Haversine formula in MySQL — calculates great-circle distance in km
    const vendors = await sequelize.query(`
      SELECT 
        v.id,
        v.user_id,
        v.is_active,
        v.lat,
        v.lng,
        u.mobile,
        (
          6371 * ACOS(
            LEAST(1, 
              COS(RADIANS(:lat)) * COS(RADIANS(v.lat)) * COS(RADIANS(v.lng) - RADIANS(:lng))
              + SIN(RADIANS(:lat)) * SIN(RADIANS(v.lat))
            )
          )
        ) AS distance_km
      FROM vendors v
      INNER JOIN users u ON v.user_id = u.id
      WHERE v.is_active = true
        AND v.lat IS NOT NULL
        AND v.lng IS NOT NULL
      HAVING distance_km <= :radius
      ORDER BY distance_km ASC
      LIMIT 50
    `, {
      replacements: { lat, lng, radius },
      type: QueryTypes.SELECT,
    });

    // Enrich with Redis-cached real-time locations (if available)
    const enriched = await Promise.all(
      vendors.map(async (v) => {
        let vendorLat = parseFloat(v.lat);
        let vendorLng = parseFloat(v.lng);

        // Try Redis for fresher location
        try {
          const cached = await redis.hgetall(`vendor_location:${v.id}`);
          if (cached && cached.lat && cached.lng) {
            vendorLat = parseFloat(cached.lat);
            vendorLng = parseFloat(cached.lng);
          }
        } catch (err) {
          // Redis miss is fine, use DB values
        }

        return {
          id: v.id,
          user_id: v.user_id,
          mobile: v.mobile,
          lat: vendorLat,
          lng: vendorLng,
          is_active: v.is_active === 1 || v.is_active === true,
          distance_km: Math.round(v.distance_km * 100) / 100,
        };
      })
    );

    return enriched;
  },

  /**
   * Get vendor details by vendor ID
   * Includes user info
   */
  async getVendorDetails(vendorId) {
    const vendor = await Vendor.findByPk(vendorId, {
      attributes: ['id', 'is_active', 'lat', 'lng', 'created_at'],
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'mobile'],
      }],
    });

    if (!vendor) {
      throw ApiError.notFound('Vendor not found', 'VENDOR_NOT_FOUND');
    }

    return vendor;
  },

  /**
   * Get vendor's available items
   * Only returns non-deleted, available items
   */
  async getVendorItems(vendorId) {
    const vendor = await Vendor.findByPk(vendorId);
    if (!vendor) {
      throw ApiError.notFound('Vendor not found', 'VENDOR_NOT_FOUND');
    }

    const items = await Item.findAll({
      where: {
        vendor_id: vendorId,
        is_available: true,
      },
      attributes: ['id', 'name', 'price', 'quantity', 'is_available'],
      order: [['name', 'ASC']],
    });

    return items;
  },

  /**
   * Get ETA for a vendor to reach a location
   * Uses active route progress + Haversine distance estimation
   *
   * @param {number} vendorId - Vendor ID
   * @param {number} buyerLat - Buyer's latitude
   * @param {number} buyerLng - Buyer's longitude
   */
  async getVendorETA(vendorId, buyerLat, buyerLng) {
    const vendor = await Vendor.findByPk(vendorId, {
      attributes: ['id', 'lat', 'lng', 'is_active', 'current_route_id', 'current_route_index'],
    });

    if (!vendor) {
      throw ApiError.notFound('Vendor not found', 'VENDOR_NOT_FOUND');
    }

    if (!vendor.is_active || !vendor.lat || !vendor.lng) {
      return { eta_minutes: null, distance_km: null, message: 'Vendor is not active or location unavailable' };
    }

    // Get fresher location from Redis if available
    let vendorLat = parseFloat(vendor.lat);
    let vendorLng = parseFloat(vendor.lng);

    try {
      const cached = await redis.hgetall(`vendor_location:${vendor.id}`);
      if (cached && cached.lat && cached.lng) {
        vendorLat = parseFloat(cached.lat);
        vendorLng = parseFloat(cached.lng);
      }
    } catch (err) {
      // Use DB location
    }

    // Calculate direct distance in km (Haversine)
    const R = 6371;
    const dLat = (buyerLat - vendorLat) * Math.PI / 180;
    const dLng = (buyerLng - vendorLng) * Math.PI / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(vendorLat * Math.PI / 180) * Math.cos(buyerLat * Math.PI / 180) *
      Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distanceKm = R * c;

    // Estimate ETA: assume average speed of 15 km/h for street vendor (walking/slow vehicle)
    const AVG_SPEED_KMH = 15;
    const etaMinutes = Math.round((distanceKm / AVG_SPEED_KMH) * 60);

    return {
      vendor_id: vendor.id,
      vendor_lat: vendorLat,
      vendor_lng: vendorLng,
      buyer_lat: buyerLat,
      buyer_lng: buyerLng,
      distance_km: Math.round(distanceKm * 100) / 100,
      eta_minutes: etaMinutes,
      speed_assumption_kmh: AVG_SPEED_KMH,
      has_active_route: !!vendor.current_route_id,
    };
  },

  /**
   * Toggle favorite vendor for a buyer
   * If already favorited → unfavorite (delete)
   * If not favorited → favorite (create)
   */
  async toggleFavorite(userId, vendorId) {
    // Verify vendor exists
    const vendor = await Vendor.findByPk(vendorId);
    if (!vendor) {
      throw ApiError.notFound('Vendor not found', 'VENDOR_NOT_FOUND');
    }

    // Check if already favorited
    const existing = await Favorite.findOne({
      where: { user_id: userId, vendor_id: vendorId },
    });

    if (existing) {
      // Unfavorite
      await existing.destroy();
      return { favorited: false, vendor_id: vendorId };
    }

    // Favorite
    await Favorite.create({ user_id: userId, vendor_id: vendorId });
    return { favorited: true, vendor_id: vendorId };
  },

  /**
   * Get user's favorite vendors
   */
  async getFavorites(userId) {
    const favorites = await Favorite.findAll({
      where: { user_id: userId },
      include: [{
        model: Vendor,
        as: 'vendor',
        attributes: ['id', 'is_active', 'lat', 'lng'],
        include: [{
          model: User,
          as: 'user',
          attributes: ['id', 'mobile'],
        }],
      }],
      order: [['created_at', 'DESC']],
    });

    return favorites;
  },

  /**
   * Get all currently active vendors (admin endpoint)
   */
  async getActiveVendors() {
    const vendors = await Vendor.findAll({
      where: { is_active: true },
      attributes: ['id', 'lat', 'lng', 'created_at', 'updated_at'],
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'mobile'],
      }],
      order: [['updated_at', 'DESC']],
    });

    return {
      count: vendors.length,
      vendors,
    };
  },
};

module.exports = vendorService;
