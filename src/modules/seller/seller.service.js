const { User, Vendor, Item, Order, sequelize } = require('../../models');
const ApiError = require('../../utils/ApiError');
const socketEmitter = require('../../utils/socketEmitter');
const redis = require('../../config/redis');
const proximityService = require('../../utils/proximity');
const { Op } = require('sequelize');

const sellerService = {
  /**
   * Register a buyer as a seller
   * Creates a vendor record and upgrades user role to 'seller'
   */
  async register(userId, vehicleName) {
    // Check if already a seller
    const existingVendor = await Vendor.findOne({ where: { user_id: userId } });
    if (existingVendor) {
      throw ApiError.badRequest('You are already registered as a seller', 'ALREADY_SELLER');
    }

    // Use transaction for atomicity
    const result = await sequelize.transaction(async (t) => {
      // Create vendor record
      const vendor = await Vendor.create({
        user_id: userId,
        is_active: false,
      }, { transaction: t });

      // Update user role to seller
      await User.update(
        { role: 'seller' },
        { where: { id: userId }, transaction: t }
      );

      return vendor;
    });

    // Fetch updated user with vendor
    const user = await User.findByPk(userId, {
      attributes: ['id', 'mobile', 'role'],
      include: [{
        model: Vendor,
        as: 'vendor',
        attributes: ['id', 'is_active'],
      }],
    });

    return user;
  },

  /**
   * Get seller dashboard data
   * Returns active status, today's order counts, and item count
   */
  async getDashboard(userId) {
    const vendor = await Vendor.findOne({
      where: { user_id: userId },
      attributes: ['id', 'is_active', 'lat', 'lng'],
    });

    if (!vendor) {
      throw ApiError.notFound('Vendor profile not found', 'VENDOR_NOT_FOUND');
    }

    // Get today's order counts
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [totalOrders, activeOrders, fulfilledOrders] = await Promise.all([
      Order.count({
        where: {
          vendor_id: vendor.id,
          created_at: { [Op.gte]: today },
        },
      }),
      Order.count({
        where: {
          vendor_id: vendor.id,
          status: { [Op.in]: ['requested', 'accepted'] },
        },
      }),
      Order.count({
        where: {
          vendor_id: vendor.id,
          status: 'fulfilled',
          created_at: { [Op.gte]: today },
        },
      }),
    ]);

    // Get item count
    const itemCount = await Item.count({
      where: { vendor_id: vendor.id },
    });

    return {
      vendor: {
        id: vendor.id,
        is_active: vendor.is_active,
        lat: vendor.lat,
        lng: vendor.lng,
      },
      stats: {
        total_orders_today: totalOrders,
        active_orders: activeOrders,
        fulfilled_today: fulfilledOrders,
        total_items: itemCount,
      },
    };
  },

  /**
   * Toggle vendor selling status (online/offline)
   */
  async toggleStatus(userId, isActive) {
    const vendor = await Vendor.findOne({ where: { user_id: userId } });

    if (!vendor) {
      throw ApiError.notFound('Vendor profile not found', 'VENDOR_NOT_FOUND');
    }

    vendor.is_active = isActive;
    await vendor.save();

    return {
      id: vendor.id,
      is_active: vendor.is_active,
    };
  },

  /**
   * Update vendor's current location
   * Writes to DB directly. In Stage 4, this will also write to Redis + broadcast via Socket.IO
   */
  async updateLocation(userId, lat, lng) {
    const vendor = await Vendor.findOne({ where: { user_id: userId } });

    if (!vendor) {
      throw ApiError.notFound('Vendor profile not found', 'VENDOR_NOT_FOUND');
    }

    vendor.lat = lat;
    vendor.lng = lng;
    await vendor.save();

    // Write to Redis for real-time location reads (optional)
    try {
      const locationKey = `vendor_location:${vendor.id}`;
      await redis.hset(locationKey, {
        lat: lat.toString(),
        lng: lng.toString(),
        updated_at: Date.now().toString(),
      });
      await redis.expire(locationKey, 3600);
    } catch (redisErr) {
      // Redis unavailable — location still saved to DB above
    }

    // Broadcast location update via socket
    socketEmitter.broadcastVendorLocation(vendor.id, {
      vendor_id: vendor.id,
      lat: parseFloat(lat),
      lng: parseFloat(lng),
      timestamp: new Date().toISOString(),
    });

    // Check proximity for active orders
    await proximityService.checkProximity(vendor.id, parseFloat(lat), parseFloat(lng));

    return {
      id: vendor.id,
      lat: vendor.lat,
      lng: vendor.lng,
    };
  },
};

module.exports = sellerService;
