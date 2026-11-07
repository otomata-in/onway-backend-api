const { Order, Vendor, User } = require('../models');
const socketEmitter = require('./socketEmitter');
const notificationService = require('./notificationService');
const { Op } = require('sequelize');

/**
 * Proximity detection utility
 *
 * Logic from design doc:
 * - Enter zone: < 100m → notify buyer
 * - Exit zone: > 120m (after enter) → expire order (buffer to prevent flapping)
 * - Debounce: 3-5 sec (handled via Redis timestamps)
 */

// Thresholds in meters
const ENTER_RADIUS = 100;
const EXIT_RADIUS = 120;
const DEBOUNCE_MS = 3000;

// In-memory debounce tracker (order_id → last_check_timestamp)
const debounceMap = new Map();

const proximityService = {
  /**
   * Calculate distance between two GPS points using Haversine formula
   * @returns {number} Distance in meters
   */
  calculateDistance(lat1, lng1, lat2, lng2) {
    const R = 6371000; // Earth's radius in meters
    const dLat = this._toRad(lat2 - lat1);
    const dLng = this._toRad(lng2 - lng1);

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this._toRad(lat1)) * Math.cos(this._toRad(lat2)) *
      Math.sin(dLng / 2) * Math.sin(dLng / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  },

  _toRad(degrees) {
    return degrees * (Math.PI / 180);
  },

  /**
   * Check proximity for all active orders of a vendor
   * Called on every vendor location update
   *
   * @param {number} vendorId - Vendor ID
   * @param {number} vendorLat - Vendor's current latitude
   * @param {number} vendorLng - Vendor's current longitude
   */
  async checkProximity(vendorId, vendorLat, vendorLng) {
    try {
      // Get all active orders (requested + accepted) for this vendor
      const activeOrders = await Order.findAll({
        where: {
          vendor_id: vendorId,
          status: { [Op.in]: ['requested', 'accepted'] },
          buyer_lat: { [Op.ne]: null },
          buyer_lng: { [Op.ne]: null },
        },
        attributes: ['id', 'buyer_id', 'buyer_lat', 'buyer_lng', 'has_entered_zone', 'status'],
      });

      if (activeOrders.length === 0) return;

      for (const order of activeOrders) {
        // Debounce check
        const lastCheck = debounceMap.get(order.id);
        const now = Date.now();
        if (lastCheck && (now - lastCheck) < DEBOUNCE_MS) {
          continue;
        }
        debounceMap.set(order.id, now);

        const distance = this.calculateDistance(
          vendorLat, vendorLng,
          parseFloat(order.buyer_lat), parseFloat(order.buyer_lng)
        );

        if (!order.has_entered_zone && distance <= ENTER_RADIUS) {
          // ENTERING zone — notify buyer
          await this._handleEnterZone(order, vendorId, distance);
        } else if (order.has_entered_zone && distance > EXIT_RADIUS) {
          // EXITING zone — expire order
          await this._handleExitZone(order, vendorId);
        }
      }

      // Cleanup old debounce entries (prevent memory leak)
      if (debounceMap.size > 1000) {
        const cutoff = Date.now() - 60000;
        for (const [key, val] of debounceMap) {
          if (val < cutoff) debounceMap.delete(key);
        }
      }
    } catch (error) {
      console.error('Proximity check error:', error.message);
    }
  },

  /**
   * Handle vendor entering buyer's zone
   */
  async _handleEnterZone(order, vendorId, distance) {
    try {
      // Mark zone entered
      order.has_entered_zone = true;
      await order.save();

      // Notify buyer via socket
      socketEmitter.notifyVendorNearby(order.buyer_id, vendorId, distance);

      // Send FCM push notification
      notificationService.notifyVendorNearby(order.buyer_id, vendorId, distance);

      console.log(`📍 Vendor ${vendorId} entered zone for order ${order.id} (${Math.round(distance)}m)`);
    } catch (error) {
      console.error('Enter zone error:', error.message);
    }
  },

  /**
   * Handle vendor exiting buyer's zone (after having entered)
   */
  async _handleExitZone(order, vendorId) {
    try {
      // Expire the order
      order.status = 'expired';
      order.expired_at = new Date();
      await order.save();

      // Notify buyer via socket
      socketEmitter.notifyOrderExpired(order.buyer_id, order.id);

      // Send FCM push notification
      notificationService.notifyOrderExpired(order.buyer_id, order.id);

      // Clean up debounce
      debounceMap.delete(order.id);

      console.log(`📍 Vendor ${vendorId} exited zone — order ${order.id} expired`);
    } catch (error) {
      console.error('Exit zone error:', error.message);
    }
  },
};

module.exports = proximityService;
