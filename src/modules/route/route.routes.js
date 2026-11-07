const express = require('express');
const router = express.Router();
const routeController = require('./route.controller');
const validate = require('../../middleware/validate');
const routeValidator = require('./route.validator');
const { authenticate, authorize } = require('../../middleware/authenticate');

// All route endpoints require seller auth
router.use(authenticate, authorize('seller'));

// GET /seller/routes/active — Get active route (must be before /:id to avoid conflict)
router.get(
  '/active',
  routeController.getActiveRoute
);

// POST /seller/routes — Create route
router.post(
  '/',
  validate(routeValidator.createRoute),
  routeController.createRoute
);

// GET /seller/routes — List all routes
router.get(
  '/',
  routeController.getRoutes
);

// PUT /seller/routes/:id — Update route
router.put(
  '/:id',
  validate(routeValidator.updateRoute),
  routeController.updateRoute
);

// DELETE /seller/routes/:id — Delete route
router.delete(
  '/:id',
  validate(routeValidator.routeId),
  routeController.deleteRoute
);

// POST /seller/routes/:id/activate — Activate route
router.post(
  '/:id/activate',
  validate(routeValidator.routeId),
  routeController.activateRoute
);

module.exports = router;
