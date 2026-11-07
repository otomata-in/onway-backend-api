const prisma = require('../config/prisma');

/**
 * GET /api/v1/vendor/routes
 * List all saved selling routes for the vendor
 */
async function getRoutes(req, res) {
  try {
    const { profileId } = req.user;
    const routes = await prisma.sellingRoute.findMany({
      where: { vendorId: profileId },
      include: { waypoints: { orderBy: { sequenceOrder: 'asc' } } },
      orderBy: { createdAt: 'desc' },
    });
    return res.json({ success: true, data: routes });
  } catch (error) {
    console.error('Error in getRoutes:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
}

/**
 * GET /api/v1/vendor/routes/active
 * Get the currently active selling route with full waypoints
 */
async function getActiveRoute(req, res) {
  try {
    const { profileId } = req.user;
    const route = await prisma.sellingRoute.findFirst({
      where: { vendorId: profileId, isActive: true },
      include: { waypoints: { orderBy: { sequenceOrder: 'asc' } } },
    });
    return res.json({ success: true, data: route });
  } catch (error) {
    console.error('Error in getActiveRoute:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
}

/**
 * POST /api/v1/vendor/routes
 * Create a new selling route with waypoints. Deactivates all other routes first.
 */
async function createRoute(req, res) {
  try {
    const { profileId } = req.user;
    const { name, description, totalDistanceKm, waypoints } = req.body;

    if (!name || !waypoints || !Array.isArray(waypoints) || waypoints.length < 2) {
      return res.status(400).json({ success: false, error: 'Name and at least 2 waypoints are required' });
    }

    const result = await prisma.$transaction(async (tx) => {
      // Deactivate all existing routes for this vendor
      await tx.sellingRoute.updateMany({
        where: { vendorId: profileId, isActive: true },
        data: { isActive: false },
      });

      // Create new route with waypoints
      const newRoute = await tx.sellingRoute.create({
        data: {
          vendorId: profileId,
          name,
          description: description || `${waypoints.length} Waypoints`,
          totalDistanceKm: totalDistanceKm || 0,
          isActive: true,
          waypoints: {
            create: waypoints.map((wp) => ({
              name: wp.name,
              latitude: wp.latitude,
              longitude: wp.longitude,
              sequenceOrder: wp.sequenceOrder,
              isStart: wp.isStart || false,
              isEnd: wp.isEnd || false,
            })),
          },
        },
        include: { waypoints: { orderBy: { sequenceOrder: 'asc' } } },
      });
      return newRoute;
    });

    return res.status(201).json({ success: true, data: result });
  } catch (error) {
    console.error('Error in createRoute:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
}

/**
 * PUT /api/v1/vendor/routes/:id
 * Update route name, description, and replace all waypoints atomically
 */
async function updateRoute(req, res) {
  try {
    const { profileId } = req.user;
    const { id } = req.params;
    const { name, description, totalDistanceKm, waypoints } = req.body;

    const route = await prisma.sellingRoute.findFirst({
      where: { id, vendorId: profileId },
    });

    if (!route) {
      return res.status(404).json({ success: false, error: 'Route not found or does not belong to this vendor' });
    }

    const result = await prisma.$transaction(async (tx) => {
      // Delete old waypoints
      await tx.routeWaypoint.deleteMany({
        where: { routeId: id },
      });

      // Update route and create new waypoints
      const updatedRoute = await tx.sellingRoute.update({
        where: { id },
        data: {
          name: name || route.name,
          description: description || route.description,
          totalDistanceKm: totalDistanceKm ?? route.totalDistanceKm,
          waypoints: waypoints
            ? {
                create: waypoints.map((wp) => ({
                  name: wp.name,
                  latitude: wp.latitude,
                  longitude: wp.longitude,
                  sequenceOrder: wp.sequenceOrder,
                  isStart: wp.isStart || false,
                  isEnd: wp.isEnd || false,
                })),
              }
            : undefined,
        },
        include: { waypoints: { orderBy: { sequenceOrder: 'asc' } } },
      });
      return updatedRoute;
    });

    return res.json({ success: true, data: result });
  } catch (error) {
    console.error('Error in updateRoute:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
}

/**
 * DELETE /api/v1/vendor/routes/:id
 * Delete a route. If it was the active route, auto-activate the first remaining one.
 */
async function deleteRoute(req, res) {
  try {
    const { profileId } = req.user;
    const { id } = req.params;

    const route = await prisma.sellingRoute.findFirst({
      where: { id, vendorId: profileId },
    });

    if (!route) {
      return res.status(404).json({ success: false, error: 'Route not found or does not belong to this vendor' });
    }

    await prisma.$transaction(async (tx) => {
      // Cascade deletes waypoints via onDelete: Cascade
      await tx.sellingRoute.delete({ where: { id } });

      // If deleted route was active, activate the first remaining route
      if (route.isActive) {
        const remainingRoute = await tx.sellingRoute.findFirst({
          where: { vendorId: profileId },
          orderBy: { createdAt: 'asc' },
        });

        if (remainingRoute) {
          await tx.sellingRoute.update({
            where: { id: remainingRoute.id },
            data: { isActive: true },
          });
        }
      }
    });

    return res.json({ success: true, message: 'Route deleted successfully' });
  } catch (error) {
    console.error('Error in deleteRoute:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
}

/**
 * PATCH /api/v1/vendor/routes/:id/activate
 * Set the specified route as active, deactivate all others
 */
async function activateRoute(req, res) {
  try {
    const { profileId } = req.user;
    const { id } = req.params;

    const route = await prisma.sellingRoute.findFirst({
      where: { id, vendorId: profileId },
    });

    if (!route) {
      return res.status(404).json({ success: false, error: 'Route not found or does not belong to this vendor' });
    }

    await prisma.$transaction(async (tx) => {
      await tx.sellingRoute.updateMany({
        where: { vendorId: profileId, isActive: true },
        data: { isActive: false },
      });

      await tx.sellingRoute.update({
        where: { id },
        data: { isActive: true },
      });
    });

    return res.json({ success: true, message: 'Route activated successfully' });
  } catch (error) {
    console.error('Error in activateRoute:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
}

module.exports = {
  getRoutes,
  getActiveRoute,
  createRoute,
  updateRoute,
  deleteRoute,
  activateRoute,
};
