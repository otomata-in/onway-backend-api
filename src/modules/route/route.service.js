const { VendorRoute, VendorRoutePoint, Vendor, sequelize } = require('../../models');
const ApiError = require('../../utils/ApiError');

const routeService = {
  /**
   * Get the vendor record for a user, or throw
   */
  async _getVendor(userId) {
    const vendor = await Vendor.findOne({ where: { user_id: userId } });
    if (!vendor) {
      throw ApiError.notFound('Vendor profile not found', 'VENDOR_NOT_FOUND');
    }
    return vendor;
  },

  /**
   * Create a new route with waypoints
   */
  async createRoute(userId, routeData) {
    const vendor = await this._getVendor(userId);
    const { name, points } = routeData;

    const result = await sequelize.transaction(async (t) => {
      // Create route
      const route = await VendorRoute.create({
        vendor_id: vendor.id,
        name,
        is_active: false,
      }, { transaction: t });

      // Create route points
      const routePoints = points.map((point) => ({
        route_id: route.id,
        lat: point.lat,
        lng: point.lng,
        sequence: point.sequence,
      }));

      await VendorRoutePoint.bulkCreate(routePoints, { transaction: t });

      return route;
    });

    // Return with points
    return this._getRouteWithPoints(result.id);
  },

  /**
   * Get all routes for a seller
   */
  async getRoutes(userId) {
    const vendor = await this._getVendor(userId);

    const routes = await VendorRoute.findAll({
      where: { vendor_id: vendor.id },
      include: [{
        model: VendorRoutePoint,
        as: 'points',
        attributes: ['id', 'lat', 'lng', 'sequence'],
        order: [['sequence', 'ASC']],
      }],
      order: [['created_at', 'DESC']],
    });

    return routes;
  },

  /**
   * Update a route (name and/or points)
   */
  async updateRoute(userId, routeId, updateData) {
    const vendor = await this._getVendor(userId);

    const route = await VendorRoute.findOne({
      where: { id: routeId, vendor_id: vendor.id },
    });

    if (!route) {
      throw ApiError.notFound('Route not found', 'ROUTE_NOT_FOUND');
    }

    await sequelize.transaction(async (t) => {
      // Update name if provided
      if (updateData.name !== undefined) {
        route.name = updateData.name;
        await route.save({ transaction: t });
      }

      // Replace points if provided
      if (updateData.points) {
        // Delete existing points
        await VendorRoutePoint.destroy({
          where: { route_id: route.id },
          transaction: t,
        });

        // Create new points
        const routePoints = updateData.points.map((point) => ({
          route_id: route.id,
          lat: point.lat,
          lng: point.lng,
          sequence: point.sequence,
        }));

        await VendorRoutePoint.bulkCreate(routePoints, { transaction: t });
      }
    });

    return this._getRouteWithPoints(route.id);
  },

  /**
   * Delete a route
   * Cannot delete if it's the currently active route
   */
  async deleteRoute(userId, routeId) {
    const vendor = await this._getVendor(userId);

    const route = await VendorRoute.findOne({
      where: { id: routeId, vendor_id: vendor.id },
    });

    if (!route) {
      throw ApiError.notFound('Route not found', 'ROUTE_NOT_FOUND');
    }

    // Cannot delete active route
    if (vendor.current_route_id === route.id) {
      throw ApiError.badRequest(
        'Cannot delete the currently active route. Deactivate it first.',
        'ACTIVE_ROUTE_DELETE'
      );
    }

    // Delete route (cascade deletes points)
    await route.destroy();

    return { message: 'Route deleted successfully' };
  },

  /**
   * Activate a route
   * Deactivates any previously active route for this vendor
   */
  async activateRoute(userId, routeId) {
    const vendor = await this._getVendor(userId);

    const route = await VendorRoute.findOne({
      where: { id: routeId, vendor_id: vendor.id },
    });

    if (!route) {
      throw ApiError.notFound('Route not found', 'ROUTE_NOT_FOUND');
    }

    await sequelize.transaction(async (t) => {
      // Deactivate all vendor routes
      await VendorRoute.update(
        { is_active: false },
        { where: { vendor_id: vendor.id }, transaction: t }
      );

      // Activate this route
      route.is_active = true;
      await route.save({ transaction: t });

      // Set vendor's current route
      vendor.current_route_id = route.id;
      vendor.current_route_index = 0;
      await vendor.save({ transaction: t });
    });

    return this._getRouteWithPoints(route.id);
  },

  /**
   * Get the currently active route for a vendor
   */
  async getActiveRoute(userId) {
    const vendor = await this._getVendor(userId);

    if (!vendor.current_route_id) {
      return null;
    }

    const route = await this._getRouteWithPoints(vendor.current_route_id);
    return {
      ...route.toJSON(),
      current_route_index: vendor.current_route_index,
    };
  },

  /**
   * Get a vendor's active route (buyer-facing)
   * Used by buyers to see the vendor's route on the map
   */
  async getVendorActiveRoute(vendorId) {
    const vendor = await Vendor.findByPk(vendorId);
    if (!vendor) {
      throw ApiError.notFound('Vendor not found', 'VENDOR_NOT_FOUND');
    }

    if (!vendor.current_route_id) {
      return null;
    }

    const route = await this._getRouteWithPoints(vendor.current_route_id);
    return {
      ...route.toJSON(),
      current_route_index: vendor.current_route_index,
    };
  },

  /**
   * Helper: get route with its ordered points
   */
  async _getRouteWithPoints(routeId) {
    return VendorRoute.findByPk(routeId, {
      include: [{
        model: VendorRoutePoint,
        as: 'points',
        attributes: ['id', 'lat', 'lng', 'sequence'],
      }],
      order: [[{ model: VendorRoutePoint, as: 'points' }, 'sequence', 'ASC']],
    });
  },
};

module.exports = routeService;
