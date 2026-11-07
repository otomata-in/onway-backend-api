const routeService = require('./route.service');
const ApiResponse = require('../../utils/ApiResponse');

const routeController = {
  /**
   * POST /seller/routes
   * Create a new route with waypoints
   */
  async createRoute(req, res, next) {
    try {
      const route = await routeService.createRoute(req.user.id, req.body);
      return ApiResponse.created(res, route, 'Route created successfully');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /seller/routes
   * Get all seller's routes
   */
  async getRoutes(req, res, next) {
    try {
      const routes = await routeService.getRoutes(req.user.id);
      return ApiResponse.success(res, routes, 'Routes retrieved');
    } catch (error) {
      next(error);
    }
  },

  /**
   * PUT /seller/routes/:id
   * Update a route
   */
  async updateRoute(req, res, next) {
    try {
      const route = await routeService.updateRoute(req.user.id, req.params.id, req.body);
      return ApiResponse.success(res, route, 'Route updated successfully');
    } catch (error) {
      next(error);
    }
  },

  /**
   * DELETE /seller/routes/:id
   * Delete a route
   */
  async deleteRoute(req, res, next) {
    try {
      const result = await routeService.deleteRoute(req.user.id, req.params.id);
      return ApiResponse.success(res, result, 'Route deleted');
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /seller/routes/:id/activate
   * Activate a route
   */
  async activateRoute(req, res, next) {
    try {
      const route = await routeService.activateRoute(req.user.id, req.params.id);
      return ApiResponse.success(res, route, 'Route activated');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /seller/routes/active
   * Get the currently active route
   */
  async getActiveRoute(req, res, next) {
    try {
      const route = await routeService.getActiveRoute(req.user.id);
      if (!route) {
        return ApiResponse.success(res, null, 'No active route');
      }
      return ApiResponse.success(res, route, 'Active route retrieved');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /vendors/:id/route
   * Get vendor's active route (buyer-facing)
   */
  async getVendorRoute(req, res, next) {
    try {
      const route = await routeService.getVendorActiveRoute(req.params.id);
      if (!route) {
        return ApiResponse.success(res, null, 'Vendor has no active route');
      }
      return ApiResponse.success(res, route, 'Vendor route retrieved');
    } catch (error) {
      next(error);
    }
  },
};

module.exports = routeController;
