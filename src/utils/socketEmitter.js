const { getIO } = require('../config/socket');

/**
 * Socket emitter utility
 * Provides named methods for emitting events to specific channels.
 * Can be called from any service/controller.
 */
const socketEmitter = {
  /**
   * Emit event to a specific vendor (seller)
   * Used for: new_order, order updates
   * @param {number} vendorUserId - The user_id of the vendor
   * @param {string} event - Event name
   * @param {object} data - Event payload
   */
  toVendor(vendorUserId, event, data) {
    const io = getIO();
    if (!io) return;
    io.to(`vendor_user_${vendorUserId}`).emit(event, data);
  },

  /**
   * Emit event to a specific buyer
   * Used for: order_update, vendor_nearby, order_expired
   * @param {number} buyerUserId - The user_id of the buyer
   * @param {string} event - Event name
   * @param {object} data - Event payload
   */
  toBuyer(buyerUserId, event, data) {
    const io = getIO();
    if (!io) return;
    io.to(`buyer_${buyerUserId}`).emit(event, data);
  },

  /**
   * Broadcast vendor location to all connected clients
   * @param {number} vendorId - The vendor ID
   * @param {object} locationData - { vendor_id, lat, lng, timestamp }
   */
  broadcastVendorLocation(vendorId, locationData) {
    const io = getIO();
    if (!io) return;
    io.emit('vendor_location_update', locationData);
  },

  // ─── Convenience Methods ─────────────────────────────────────

  /**
   * Notify vendor of new incoming order
   */
  notifyNewOrder(vendorUserId, orderData) {
    this.toVendor(vendorUserId, 'new_order', {
      type: 'new_order',
      order: orderData,
      timestamp: new Date().toISOString(),
    });
  },

  /**
   * Notify buyer of order status change
   */
  notifyOrderUpdate(buyerUserId, orderId, status) {
    this.toBuyer(buyerUserId, 'order_update', {
      type: 'order_update',
      order_id: orderId,
      status,
      timestamp: new Date().toISOString(),
    });
  },

  /**
   * Notify buyer that vendor is nearby
   */
  notifyVendorNearby(buyerUserId, vendorId, distance) {
    this.toBuyer(buyerUserId, 'vendor_nearby', {
      type: 'vendor_nearby',
      vendor_id: vendorId,
      distance_meters: Math.round(distance),
      timestamp: new Date().toISOString(),
    });
  },

  /**
   * Notify buyer that order has expired (vendor passed)
   */
  notifyOrderExpired(buyerUserId, orderId) {
    this.toBuyer(buyerUserId, 'order_expired', {
      type: 'order_expired',
      order_id: orderId,
      timestamp: new Date().toISOString(),
    });
  },

  /**
   * Emit route progress update
   */
  emitRouteProgress(vendorId, progressData) {
    const io = getIO();
    if (!io) return;
    io.emit('route_progress_update', {
      vendor_id: vendorId,
      ...progressData,
      timestamp: new Date().toISOString(),
    });
  },
};

module.exports = socketEmitter;
