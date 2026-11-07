const orderService = require('./order.service');
const ApiResponse = require('../../utils/ApiResponse');

const orderController = {
  /**
   * POST /orders
   * Create a new order token (buyer intent)
   */
  async createOrder(req, res, next) {
    try {
      const order = await orderService.createOrder(req.user.id, req.body);
      return ApiResponse.created(res, order, 'Order token created successfully');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /orders
   * Get buyer's orders (paginated)
   */
  async getBuyerOrders(req, res, next) {
    try {
      const result = await orderService.getBuyerOrders(req.user.id, req.query);
      return ApiResponse.paginated(
        res,
        result.orders,
        result.page,
        result.limit,
        result.total,
        'Orders retrieved'
      );
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /orders/:id
   * Get order details
   */
  async getOrderById(req, res, next) {
    try {
      const order = await orderService.getOrderById(req.params.id, req.user.id);
      return ApiResponse.success(res, order, 'Order details retrieved');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /seller/orders
   * Get seller's orders (paginated)
   */
  async getSellerOrders(req, res, next) {
    try {
      const result = await orderService.getSellerOrders(req.user.id, req.query);
      return ApiResponse.paginated(
        res,
        result.orders,
        result.page,
        result.limit,
        result.total,
        'Seller orders retrieved'
      );
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /orders/:id/accept
   * Accept an order token
   */
  async acceptOrder(req, res, next) {
    try {
      const result = await orderService.acceptOrder(req.params.id, req.user.id);
      return ApiResponse.success(res, result, 'Order accepted');
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /orders/:id/reject
   * Reject an order token
   */
  async rejectOrder(req, res, next) {
    try {
      const result = await orderService.rejectOrder(req.params.id, req.user.id);
      return ApiResponse.success(res, result, 'Order rejected');
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /orders/:id/fulfill
   * Mark order as fulfilled
   */
  async fulfillOrder(req, res, next) {
    try {
      const result = await orderService.fulfillOrder(req.params.id, req.user.id);
      return ApiResponse.success(res, result, 'Order fulfilled');
    } catch (error) {
      next(error);
    }
  },
};

module.exports = orderController;
