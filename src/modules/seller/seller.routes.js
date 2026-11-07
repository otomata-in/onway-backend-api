const express = require('express');
const router = express.Router();
const sellerController = require('./seller.controller');
const orderController = require('../order/order.controller');
const validate = require('../../middleware/validate');
const sellerValidator = require('./seller.validator');
const orderValidator = require('../order/order.validator');
const { authenticate, authorize } = require('../../middleware/authenticate');

// POST /seller/register — Register as seller (any authenticated user)
router.post(
  '/register',
  authenticate,
  validate(sellerValidator.register),
  sellerController.register
);

// All routes below require seller role
router.use(authenticate, authorize('seller'));

// GET /seller/dashboard — Seller dashboard
router.get(
  '/dashboard',
  sellerController.getDashboard
);

// GET /seller/orders — Get seller's orders (paginated, filterable by status)
router.get(
  '/orders',
  validate(orderValidator.getOrders),
  orderController.getSellerOrders
);

module.exports = router;

