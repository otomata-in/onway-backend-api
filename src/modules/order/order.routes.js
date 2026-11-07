const express = require('express');
const router = express.Router();
const orderController = require('./order.controller');
const validate = require('../../middleware/validate');
const orderValidator = require('./order.validator');
const { authenticate, authorize } = require('../../middleware/authenticate');

// All order routes require authentication
router.use(authenticate);

// ─── Buyer-side ─────────────────────────────────────────────────

// POST /orders — Create order token
router.post(
  '/',
  validate(orderValidator.createOrder),
  orderController.createOrder
);

// GET /orders — Get buyer's orders (paginated)
router.get(
  '/',
  validate(orderValidator.getOrders),
  orderController.getBuyerOrders
);

// GET /orders/:id — Order details
router.get(
  '/:id',
  validate(orderValidator.orderId),
  orderController.getOrderById
);

// ─── Seller-side (status updates) ───────────────────────────────

// POST /orders/:id/accept — Accept order
router.post(
  '/:id/accept',
  authorize('seller'),
  validate(orderValidator.orderId),
  orderController.acceptOrder
);

// POST /orders/:id/reject — Reject order
router.post(
  '/:id/reject',
  authorize('seller'),
  validate(orderValidator.orderId),
  orderController.rejectOrder
);

// POST /orders/:id/fulfill — Fulfill order
router.post(
  '/:id/fulfill',
  authorize('seller'),
  validate(orderValidator.orderId),
  orderController.fulfillOrder
);

module.exports = router;
