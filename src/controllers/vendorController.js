const prisma = require('../config/prisma');

/**
  GET /api/v1/vendor/dashboard-stats
  Returns business performance metrics (Total Enquiries, Today's, Completed, Pending, Missed)
 */
async function getDashboardStats(req, res) {
  try {
    const vendorId = req.user?.profileId || req.query.vendorId;

    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);

    const totalEnquiries = await prisma.orderEnquiry.count({
      where: vendorId ? { vendorId } : {},
    });

    const todaysEnquiriesCount = await prisma.orderEnquiry.count({
      where: {
        ...(vendorId ? { vendorId } : {}),
        createdAt: { gte: startOfToday },
      },
    });

    const completedOrdersCount = await prisma.orderEnquiry.count({
      where: {
        ...(vendorId ? { vendorId } : {}),
        status: 'COMPLETED',
      },
    });

    const incompletedOrdersCount = await prisma.orderEnquiry.count({
      where: {
        ...(vendorId ? { vendorId } : {}),
        status: 'PENDING',
      },
    });

    const missedOrdersCount = await prisma.orderEnquiry.count({
      where: {
        ...(vendorId ? { vendorId } : {}),
        status: 'MISSED',
      },
    });

    return res.status(200).json({
      success: true,
      stats: {
        totalEnquiries,
        todaysEnquiriesCount,
        completedOrdersCount,
        incompletedOrdersCount,
        missedOrdersCount,
      },
    });
  } catch (err) {
    console.error('Error in getDashboardStats:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}

/**
  PATCH /api/v1/vendor/toggle-broadcast
  Toggles live broadcasting state (ON / OFF)
 */
async function toggleBroadcast(req, res) {
  try {
    const vendorId = req.user?.profileId || req.body.vendorId;
    const { isLiveBroadcasting } = req.body;

    if (!vendorId) {
      return res.status(400).json({ success: false, error: 'Vendor profile ID is required' });
    }

    const updated = await prisma.vendorProfile.update({
      where: { id: vendorId },
      data: { isLiveBroadcasting },
    });

    return res.status(200).json({
      success: true,
      isLiveBroadcasting: updated.isLiveBroadcasting,
    });
  } catch (err) {
    console.error('Error in toggleBroadcast:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}

/**
  PATCH /api/v1/vendor/toggle-delivery-mode
  Toggles vendor delivery mode (ON / OFF)
 */
async function toggleDeliveryMode(req, res) {
  try {
    const vendorId = req.user?.profileId || req.body.vendorId;
    const { isDeliveryMode } = req.body;

    if (!vendorId) {
      return res.status(400).json({ success: false, error: 'Vendor profile ID is required' });
    }

    const updated = await prisma.vendorProfile.update({
      where: { id: vendorId },
      data: { isDeliveryMode },
    });

    return res.status(200).json({
      success: true,
      isDeliveryMode: updated.isDeliveryMode,
    });
  } catch (err) {
    console.error('Error in toggleDeliveryMode:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}

/**
  POST /api/v1/vendor/update-location
  Ingests real-time GPS location coordinates of moving vendor
 */
async function updateLocation(req, res) {
  try {
    const vendorId = req.user?.profileId || req.body.vendorId;
    const { latitude, longitude, heading = 0, speed = 0 } = req.body;

    if (!vendorId || latitude === undefined || longitude === undefined) {
      return res.status(400).json({ success: false, error: 'Vendor ID, latitude, and longitude are required' });
    }

    // Update Vendor Profile current position
    await prisma.vendorProfile.update({
      where: { id: vendorId },
      data: {
        currentLatitude: latitude,
        currentLongitude: longitude,
      },
    });

    // Save live location point
    const liveLoc = await prisma.liveVendorLocation.create({
      data: {
        vendorId,
        latitude,
        longitude,
        heading,
        speed,
      },
    });

    return res.status(200).json({
      success: true,
      location: liveLoc,
    });
  } catch (err) {
    console.error('Error in updateLocation:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}

module.exports = {
  getDashboardStats,
  toggleBroadcast,
  toggleDeliveryMode,
  updateLocation,
};
