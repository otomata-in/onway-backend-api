const prisma = require('../config/prisma');
const { sendSmsOtp } = require('../services/twilioService');

/**
  GET /api/v1/orders/todays
  Fetches today's enquiries sorted by proximity
 */
async function getTodaysEnquiries(req, res) {
  try {
    const vendorId = req.user?.profileId || req.query.vendorId;

    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);

    const enquiries = await prisma.orderEnquiry.findMany({
      where: {
        ...(vendorId ? { vendorId } : {}),
        createdAt: { gte: startOfToday },
      },
      include: {
        items: true,
        waypoint: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return res.status(200).json({
      success: true,
      count: enquiries.length,
      enquiries,
    });
  } catch (err) {
    console.error('Error in getTodaysEnquiries:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}

/**
  GET /api/v1/orders/history
  Advanced senior-friendly multi-criteria order history & analytics endpoint
 */
async function getOrderHistory(req, res) {
  try {
    const vendorId = req.user?.profileId || req.query.vendorId;
    const {
      timeFilter = 'ALL_TIME', // TODAY, YESTERDAY, LAST_WEEK, LAST_MONTH, CUSTOM, ALL_TIME
      startDate,
      endDate,
      search,
      waypointId,
      statusFilter, // PENDING, COMPLETED, MISSED, INCOMPLETE
      maxDistanceRadius = 5000,
    } = req.query;

    const whereClause = {};
    if (vendorId) whereClause.vendorId = vendorId;

    // Time Range Filter Logic
    const now = new Date();
    if (timeFilter === 'TODAY') {
      const start = new Date();
      start.setHours(0, 0, 0, 0);
      whereClause.createdAt = { gte: start };
    } else if (timeFilter === 'YESTERDAY') {
      const start = new Date();
      start.setDate(start.getDate() - 1);
      start.setHours(0, 0, 0, 0);
      const end = new Date();
      end.setDate(end.getDate() - 1);
      end.setHours(23, 59, 59, 999);
      whereClause.createdAt = { gte: start, lte: end };
    } else if (timeFilter === 'LAST_WEEK') {
      const start = new Date();
      start.setDate(start.getDate() - 7);
      whereClause.createdAt = { gte: start };
    } else if (timeFilter === 'LAST_MONTH') {
      const start = new Date();
      start.setMonth(start.getMonth() - 1);
      whereClause.createdAt = { gte: start };
    } else if (timeFilter === 'CUSTOM' && startDate && endDate) {
      whereClause.createdAt = {
        gte: new Date(startDate),
        lte: new Date(endDate),
      };
    }

    // Waypoint Filter
    if (waypointId && waypointId !== 'all') {
      whereClause.waypointId = waypointId;
    }

    // Status Filter
    if (statusFilter && statusFilter !== 'ALL') {
      whereClause.status = statusFilter.toUpperCase();
    }

    // Distance Radius Filter
    if (maxDistanceRadius) {
      whereClause.distanceMeters = { lte: parseInt(maxDistanceRadius, 10) };
    }

    // Search Query (Buyer Name, Phone, Items, Order Number)
    if (search && search.trim() !== '') {
      const query = search.trim();
      whereClause.OR = [
        { enquiryNumber: { contains: query, mode: 'insensitive' } },
        { buyerName: { contains: query, mode: 'insensitive' } },
        { buyerPhone: { contains: query, mode: 'insensitive' } },
        { notes: { contains: query, mode: 'insensitive' } },
      ];
    }

    const orders = await prisma.orderEnquiry.findMany({
      where: whereClause,
      include: {
        items: true,
        waypoint: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    // Analytics Header Metrics
    const totalAmount = orders.reduce((sum, o) => sum + o.totalAmount, 0);
    const completedCount = orders.filter((o) => o.status === 'COMPLETED').length;
    const fulfillmentRate = orders.length > 0 ? ((completedCount / orders.length) * 100).toFixed(1) : '100.0';

    return res.status(200).json({
      success: true,
      count: orders.length,
      analytics: {
        totalOrdersCount: orders.length,
        totalRevenue: totalAmount,
        completedCount,
        fulfillmentRatePercentage: parseFloat(fulfillmentRate),
      },
      orders,
    });
  } catch (err) {
    console.error('Error in getOrderHistory:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}

/**
  PATCH /api/v1/orders/:id/status
  Updates enquiry status (PENDING, COMPLETED, MISSED)
 */
async function updateOrderStatus(req, res) {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!id || !status) {
      return res.status(400).json({ success: false, error: 'Order ID and status are required' });
    }

    const updated = await prisma.orderEnquiry.update({
      where: { id },
      data: { status: status.toUpperCase() },
    });

    return res.status(200).json({
      success: true,
      order: updated,
    });
  } catch (err) {
    console.error('Error in updateOrderStatus:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}

/**
  POST /api/v1/orders/:id/ring-buyer
  Sends SMS alert via Twilio to buyer when vendor approaches (<250m)
 */
async function ringBuyer(req, res) {
  try {
    const { id } = req.params;

    const order = await prisma.orderEnquiry.findUnique({
      where: { id },
      include: { vendor: true },
    });

    if (!order) {
      return res.status(404).json({ success: false, error: 'Order enquiry not found' });
    }

    const message = `🔔 Hello ${order.buyerName}! Your OnWay vendor "${order.vendor.businessName}" is arriving now near your location (${order.distanceMeters}m away). Please keep your pre-order payment ready!`;

    // Send alert SMS via Twilio
    const twilioRes = await sendSmsOtp(order.buyerPhone, message);

    return res.status(200).json({
      success: true,
      message: `Ringing signal sent to buyer ${order.buyerName}`,
      orderId: id,
      buyerPhone: order.buyerPhone,
      twilioResult: twilioRes,
    });
  } catch (err) {
    console.error('Error in ringBuyer:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}

/**
  POST /api/v1/orders/create
  Buyer submits new pre-order enquiry
 */
async function createOrder(req, res) {
  try {
    const {
      buyerId,
      vendorId,
      routeId,
      waypointId,
      buyerName,
      buyerPhone,
      deliveryLat,
      deliveryLng,
      distanceMeters = 100,
      totalAmount,
      notes,
      items = [],
    } = req.body;

    const enquiryNumber = `ENQ-${Math.floor(100 + Math.random() * 900)}`;

    const order = await prisma.orderEnquiry.create({
      data: {
        enquiryNumber,
        buyerId: buyerId || 'mock-buyer-id',
        vendorId: vendorId || 'mock-vendor-id',
        routeId,
        waypointId,
        buyerName: buyerName || 'Buyer User',
        buyerPhone: buyerPhone || '+91 98765 43210',
        deliveryLat: deliveryLat || 9.9700,
        deliveryLng: deliveryLng || 76.2850,
        distanceMeters,
        totalAmount: totalAmount || 450.0,
        notes,
        status: 'PENDING',
        items: {
          create: items.map((item) => ({
            productName: item.name || 'Organic Produce',
            quantity: item.quantity || 1.0,
            unitPrice: item.price || 200.0,
            totalPrice: (item.quantity || 1.0) * (item.price || 200.0),
          })),
        },
      },
      include: { items: true },
    });

    return res.status(201).json({
      success: true,
      message: 'Pre-order created successfully',
      order,
    });
  } catch (err) {
    console.error('Error in createOrder:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}

module.exports = {
  getTodaysEnquiries,
  getOrderHistory,
  updateOrderStatus,
  ringBuyer,
  createOrder,
};
