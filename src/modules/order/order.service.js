const { Order, OrderItem, Item, Vendor, User, sequelize } = require('../../models');
const ApiError = require('../../utils/ApiError');
const socketEmitter = require('../../utils/socketEmitter');
const notificationService = require('../../utils/notificationService');
const { Op } = require('sequelize');

const orderService = {
  /**
   * Create an order token (buyer intent)
   * 1. Validate vendor exists and is active
   * 2. Validate all items belong to vendor and are available
   * 3. Create order + order_items in a transaction
   */
  async createOrder(buyerId, orderData) {
    const { vendor_id, buyer_lat, buyer_lng, items } = orderData;

    // Validate vendor
    const vendor = await Vendor.findByPk(vendor_id);
    if (!vendor) {
      throw ApiError.notFound('Vendor not found', 'VENDOR_NOT_FOUND');
    }
    if (!vendor.is_active) {
      throw ApiError.badRequest('Vendor is currently not selling', 'VENDOR_INACTIVE');
    }

    // Prevent buying from yourself
    if (vendor.user_id === buyerId) {
      throw ApiError.badRequest('You cannot place an order with yourself', 'SELF_ORDER');
    }

    // Validate items belong to vendor and are available
    const itemIds = items.map((i) => i.item_id);
    const vendorItems = await Item.findAll({
      where: {
        id: { [Op.in]: itemIds },
        vendor_id: vendor.id,
        is_available: true,
      },
    });

    if (vendorItems.length !== itemIds.length) {
      throw ApiError.badRequest(
        'One or more items are unavailable or do not belong to this vendor',
        'INVALID_ITEMS'
      );
    }

    // Create order with items in transaction
    const order = await sequelize.transaction(async (t) => {
      const newOrder = await Order.create({
        buyer_id: buyerId,
        vendor_id: vendor.id,
        status: 'requested',
        type: 'token',
        buyer_lat,
        buyer_lng,
      }, { transaction: t });

      // Create order items
      const orderItems = items.map((item) => ({
        order_id: newOrder.id,
        item_id: item.item_id,
        qty: item.qty,
      }));

      await OrderItem.bulkCreate(orderItems, { transaction: t });

      return newOrder;
    });

    // Fetch the complete order with items
    const fullOrder = await this.getOrderById(order.id, buyerId);

    // Emit socket event 'new_order' to vendor
    socketEmitter.notifyNewOrder(vendor.user_id, {
      id: fullOrder.id,
      buyer_id: buyerId,
      status: fullOrder.status,
      items: fullOrder.orderItems,
    });

    // Send FCM push notification to vendor
    notificationService.notifyNewOrder(vendor.user_id, {
      id: fullOrder.id,
      items: fullOrder.orderItems,
    });

    return fullOrder;
  },

  /**
   * Get buyer's orders (paginated)
   */
  async getBuyerOrders(buyerId, { page = 1, limit = 20, status }) {
    const where = { buyer_id: buyerId };
    if (status) {
      where.status = status;
    }

    const offset = (page - 1) * limit;

    const { count, rows } = await Order.findAndCountAll({
      where,
      include: [
        {
          model: Vendor,
          as: 'vendor',
          attributes: ['id'],
          include: [{
            model: User,
            as: 'user',
            attributes: ['mobile'],
          }],
        },
        {
          model: OrderItem,
          as: 'orderItems',
          attributes: ['id', 'qty'],
          include: [{
            model: Item.unscoped(),  // Include deleted items in order history
            as: 'item',
            attributes: ['id', 'name', 'price'],
          }],
        },
      ],
      order: [['created_at', 'DESC']],
      limit: parseInt(limit, 10),
      offset,
      distinct: true,  // Fix count with includes
    });

    return { orders: rows, total: count, page: parseInt(page, 10), limit: parseInt(limit, 10) };
  },

  /**
   * Get a single order by ID
   * Verifies the user is either the buyer or the vendor owner
   */
  async getOrderById(orderId, userId) {
    const order = await Order.findByPk(orderId, {
      include: [
        {
          model: User,
          as: 'buyer',
          attributes: ['id', 'mobile'],
        },
        {
          model: Vendor,
          as: 'vendor',
          attributes: ['id', 'user_id'],
          include: [{
            model: User,
            as: 'user',
            attributes: ['mobile'],
          }],
        },
        {
          model: OrderItem,
          as: 'orderItems',
          attributes: ['id', 'qty'],
          include: [{
            model: Item.unscoped(),
            as: 'item',
            attributes: ['id', 'name', 'price'],
          }],
        },
      ],
    });

    if (!order) {
      throw ApiError.notFound('Order not found', 'ORDER_NOT_FOUND');
    }

    // Check authorization: must be buyer or vendor owner
    const isAuthorized = order.buyer_id === userId || order.vendor?.user_id === userId;
    if (!isAuthorized) {
      throw ApiError.forbidden('You are not authorized to view this order');
    }

    return order;
  },

  /**
   * Get seller's orders (paginated, filtered by status)
   */
  async getSellerOrders(userId, { page = 1, limit = 20, status }) {
    // Get vendor
    const vendor = await Vendor.findOne({ where: { user_id: userId } });
    if (!vendor) {
      throw ApiError.notFound('Vendor profile not found', 'VENDOR_NOT_FOUND');
    }

    const where = { vendor_id: vendor.id };
    if (status) {
      where.status = status;
    }

    const offset = (page - 1) * limit;

    const { count, rows } = await Order.findAndCountAll({
      where,
      include: [
        {
          model: User,
          as: 'buyer',
          attributes: ['id', 'mobile'],
        },
        {
          model: OrderItem,
          as: 'orderItems',
          attributes: ['id', 'qty'],
          include: [{
            model: Item.unscoped(),
            as: 'item',
            attributes: ['id', 'name', 'price'],
          }],
        },
      ],
      order: [['created_at', 'DESC']],
      limit: parseInt(limit, 10),
      offset,
      distinct: true,
    });

    return { orders: rows, total: count, page: parseInt(page, 10), limit: parseInt(limit, 10) };
  },

  /**
   * Accept an order token
   * Only the vendor owner can accept. Status must be 'requested'.
   */
  async acceptOrder(orderId, userId) {
    return this._updateOrderStatus(orderId, userId, 'requested', 'accepted');
  },

  /**
   * Reject an order token
   * Only the vendor owner can reject. Status must be 'requested'.
   */
  async rejectOrder(orderId, userId) {
    return this._updateOrderStatus(orderId, userId, 'requested', 'rejected');
  },

  /**
   * Fulfill an order token
   * Only the vendor owner can fulfill. Status must be 'accepted'.
   */
  async fulfillOrder(orderId, userId) {
    return this._updateOrderStatus(orderId, userId, 'accepted', 'fulfilled');
  },

  /**
   * Internal: Update order status with validation
   */
  async _updateOrderStatus(orderId, userId, requiredStatus, newStatus) {
    const order = await Order.findByPk(orderId, {
      include: [{
        model: Vendor,
        as: 'vendor',
        attributes: ['id', 'user_id'],
      }],
    });

    if (!order) {
      throw ApiError.notFound('Order not found', 'ORDER_NOT_FOUND');
    }

    // Check if user owns the vendor
    if (order.vendor.user_id !== userId) {
      throw ApiError.forbidden('You are not authorized to manage this order');
    }

    // Check status transition is valid
    if (order.status !== requiredStatus) {
      throw ApiError.badRequest(
        `Cannot ${newStatus} an order with status '${order.status}'. Expected '${requiredStatus}'.`,
        'INVALID_STATUS_TRANSITION'
      );
    }

    order.status = newStatus;

    // If expired, set expired_at
    if (newStatus === 'expired') {
      order.expired_at = new Date();
    }

    await order.save();

    // Emit socket event 'order_update' to buyer
    socketEmitter.notifyOrderUpdate(order.buyer_id, order.id, order.status);

    // Send FCM push notification to buyer based on status
    if (newStatus === 'accepted') {
      notificationService.notifyOrderAccepted(order.buyer_id, order.id);
    } else if (newStatus === 'rejected') {
      notificationService.notifyOrderRejected(order.buyer_id, order.id);
    } else if (newStatus === 'fulfilled') {
      notificationService.notifyOrderFulfilled(order.buyer_id, order.id);
    }

    return {
      id: order.id,
      status: order.status,
      updated_at: order.updated_at,
    };
  },
};

module.exports = orderService;
