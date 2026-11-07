const { User, Vendor } = require('../models');
const { sendNotification } = require('./fcm');

/**
 * Push Notification Service
 *
 * High-level methods for each notification event.
 * Fetches FCM tokens from DB and sends push notifications.
 *
 * Notification types (from design doc):
 * - new_order → seller
 * - order_accepted → buyer
 * - vendor_nearby → buyer
 * - order_expired → buyer
 * - vendor_upcoming → buyer (route-based)
 */
const notificationService = {
  /**
   * Notify seller of a new incoming order
   *
   * @param {number} vendorUserId - The vendor's user_id
   * @param {object} orderData - { id, buyer_id, items }
   */
  async notifyNewOrder(vendorUserId, orderData) {
    try {
      const user = await User.findByPk(vendorUserId, {
        attributes: ['fcm_token'],
      });

      if (!user?.fcm_token) return;

      const itemCount = orderData.items?.length || 0;
      await sendNotification(
        user.fcm_token,
        {
          title: '🛒 New Order Received!',
          body: `You have a new order with ${itemCount} item${itemCount !== 1 ? 's' : ''}. Tap to view.`,
        },
        {
          type: 'new_order',
          order_id: orderData.id,
          action: 'open_order',
        }
      );
    } catch (error) {
      console.error('FCM notifyNewOrder error:', error.message);
    }
  },

  /**
   * Notify buyer that their order was accepted
   *
   * @param {number} buyerUserId - The buyer's user_id
   * @param {number} orderId - The order ID
   * @param {string} vendorMobile - Vendor's mobile for display
   */
  async notifyOrderAccepted(buyerUserId, orderId, vendorMobile) {
    try {
      const user = await User.findByPk(buyerUserId, {
        attributes: ['fcm_token'],
      });

      if (!user?.fcm_token) return;

      await sendNotification(
        user.fcm_token,
        {
          title: '✅ Order Accepted!',
          body: 'Your order has been accepted by the vendor. They\'re on their way!',
        },
        {
          type: 'order_accepted',
          order_id: orderId,
          action: 'open_order',
        }
      );
    } catch (error) {
      console.error('FCM notifyOrderAccepted error:', error.message);
    }
  },

  /**
   * Notify buyer that their order was rejected
   *
   * @param {number} buyerUserId - The buyer's user_id
   * @param {number} orderId - The order ID
   */
  async notifyOrderRejected(buyerUserId, orderId) {
    try {
      const user = await User.findByPk(buyerUserId, {
        attributes: ['fcm_token'],
      });

      if (!user?.fcm_token) return;

      await sendNotification(
        user.fcm_token,
        {
          title: '❌ Order Declined',
          body: 'Unfortunately, the vendor could not accept your order.',
        },
        {
          type: 'order_rejected',
          order_id: orderId,
          action: 'open_orders',
        }
      );
    } catch (error) {
      console.error('FCM notifyOrderRejected error:', error.message);
    }
  },

  /**
   * Notify buyer that their order was fulfilled
   *
   * @param {number} buyerUserId - The buyer's user_id
   * @param {number} orderId - The order ID
   */
  async notifyOrderFulfilled(buyerUserId, orderId) {
    try {
      const user = await User.findByPk(buyerUserId, {
        attributes: ['fcm_token'],
      });

      if (!user?.fcm_token) return;

      await sendNotification(
        user.fcm_token,
        {
          title: '🎉 Order Complete!',
          body: 'Your order has been fulfilled. Thank you for using OnWay!',
        },
        {
          type: 'order_fulfilled',
          order_id: orderId,
          action: 'open_order',
        }
      );
    } catch (error) {
      console.error('FCM notifyOrderFulfilled error:', error.message);
    }
  },

  /**
   * Notify buyer that a vendor is nearby
   *
   * @param {number} buyerUserId - The buyer's user_id
   * @param {number} vendorId - The vendor ID
   * @param {number} distance - Distance in meters
   */
  async notifyVendorNearby(buyerUserId, vendorId, distance) {
    try {
      const user = await User.findByPk(buyerUserId, {
        attributes: ['fcm_token'],
      });

      if (!user?.fcm_token) return;

      await sendNotification(
        user.fcm_token,
        {
          title: '📍 Vendor is Nearby!',
          body: `A vendor is ${Math.round(distance)}m away from you. Get ready!`,
        },
        {
          type: 'vendor_nearby',
          vendor_id: vendorId,
          distance: distance,
          action: 'open_map',
        }
      );
    } catch (error) {
      console.error('FCM notifyVendorNearby error:', error.message);
    }
  },

  /**
   * Notify buyer that their order has expired (vendor passed by)
   *
   * @param {number} buyerUserId - The buyer's user_id
   * @param {number} orderId - The order ID
   */
  async notifyOrderExpired(buyerUserId, orderId) {
    try {
      const user = await User.findByPk(buyerUserId, {
        attributes: ['fcm_token'],
      });

      if (!user?.fcm_token) return;

      await sendNotification(
        user.fcm_token,
        {
          title: '⏰ Order Expired',
          body: 'The vendor has passed your location. Your order has been expired.',
        },
        {
          type: 'order_expired',
          order_id: orderId,
          action: 'open_orders',
        }
      );
    } catch (error) {
      console.error('FCM notifyOrderExpired error:', error.message);
    }
  },

  /**
   * Notify buyer that a vendor is upcoming on their route
   * Route-based notification: vendor is heading towards buyer's area
   *
   * @param {number} buyerUserId - The buyer's user_id
   * @param {number} vendorId - The vendor ID
   * @param {number} etaMinutes - Estimated time of arrival in minutes
   */
  async notifyVendorUpcoming(buyerUserId, vendorId, etaMinutes) {
    try {
      const user = await User.findByPk(buyerUserId, {
        attributes: ['fcm_token'],
      });

      if (!user?.fcm_token) return;

      await sendNotification(
        user.fcm_token,
        {
          title: '🚚 Vendor Coming Your Way!',
          body: `A vendor is heading to your area. ETA: ~${etaMinutes} minutes.`,
        },
        {
          type: 'vendor_upcoming',
          vendor_id: vendorId,
          eta_minutes: etaMinutes,
          action: 'open_map',
        }
      );
    } catch (error) {
      console.error('FCM notifyVendorUpcoming error:', error.message);
    }
  },
};

module.exports = notificationService;
