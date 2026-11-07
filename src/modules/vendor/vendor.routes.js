const express = require('express');
const router = express.Router();
const vendorController = require('./vendor.controller');
const sellerController = require('../seller/seller.controller');
const routeController = require('../route/route.controller');
const validate = require('../../middleware/validate');
const vendorValidator = require('./vendor.validator');
const sellerValidator = require('../seller/seller.validator');
const { authenticate, authorize } = require('../../middleware/authenticate');

// ─── Buyer-facing (requires auth) ──────────────────────────────

// GET /vendors/nearby — Find nearby active vendors
router.get(
  '/nearby',
  authenticate,
  validate(vendorValidator.nearby),
  vendorController.getNearby
);

// GET /vendors/favorites — Get buyer's favorite vendors (must be before /:id)
router.get(
  '/favorites',
  authenticate,
  vendorController.getFavorites
);

// GET /vendors/:id — Vendor details
router.get(
  '/:id',
  authenticate,
  validate(vendorValidator.vendorId),
  vendorController.getVendorDetails
);

// GET /vendors/:id/items — Vendor's available items
router.get(
  '/:id/items',
  authenticate,
  validate(vendorValidator.vendorId),
  vendorController.getVendorItems
);

// GET /vendors/:id/route — Vendor's active route (for map)
router.get(
  '/:id/route',
  authenticate,
  validate(vendorValidator.vendorId),
  routeController.getVendorRoute
);

// GET /vendors/:id/eta?lat=&lng= — ETA for vendor to reach buyer
router.get(
  '/:id/eta',
  authenticate,
  validate(vendorValidator.vendorETA),
  vendorController.getVendorETA
);

// POST /vendors/:id/favorite — Toggle favorite vendor
router.post(
  '/:id/favorite',
  authenticate,
  validate(vendorValidator.vendorId),
  vendorController.toggleFavorite
);

// ─── Seller-facing ──────────────────────────────────────────────

// POST /vendors/status — Toggle selling status
router.post(
  '/status',
  authenticate,
  authorize('seller'),
  validate(sellerValidator.toggleStatus),
  sellerController.toggleStatus
);

// POST /vendors/location — Update vendor location
router.post(
  '/location',
  authenticate,
  authorize('seller'),
  validate(sellerValidator.updateLocation),
  sellerController.updateLocation
);

module.exports = router;
