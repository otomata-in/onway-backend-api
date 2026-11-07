const prisma = require('../config/prisma');

exports.createBooking = async (req, res) => {
  try {
    const { profileId } = req.user;
    const { vendorId, items, notifyOnReach, ringOnReach, dailyTracking, notes } = req.body;

    let targetVendorId = vendorId;

    // Fallback: If vendorId is not a UUID (e.g. passed vendor name), find vendor by businessName
    if (vendorId && (vendorId.length < 20 || !vendorId.includes('-'))) {
      const v = await prisma.vendorProfile.findFirst({
        where: { businessName: { contains: vendorId, mode: 'insensitive' } }
      });
      if (v) targetVendorId = v.id;
    }

    // Ensure valid vendor profile ID
    const targetVendor = await prisma.vendorProfile.findUnique({
      where: { id: targetVendorId }
    });

    if (!targetVendor) {
      // Fallback to first available broadcasting vendor
      const firstVendor = await prisma.vendorProfile.findFirst({
        where: { isLiveBroadcasting: true }
      });
      if (firstVendor) targetVendorId = firstVendor.id;
    }

    const bookingNumber = `ONW-${Math.floor(10000 + Math.random() * 90000)}`;
    const totalAmount = (items || []).reduce((acc, item) => acc + ((item.quantity || 1) * (item.unitPrice || 0)), 0);

    const booking = await prisma.$transaction(async (tx) => {
      const newBooking = await tx.booking.create({
        data: {
          bookingNumber,
          buyerId: profileId,
          vendorId: targetVendorId,
          totalAmount,
          notes,
          status: 'EN_ROUTE',
          notifyOnReach: notifyOnReach ?? true,
          ringOnReach: ringOnReach ?? true,
          dailyTracking: dailyTracking ?? false,
          items: {
            create: (items || []).map(i => ({
              productId: (i.productId && i.productId.includes('-')) ? i.productId : null,
              productName: i.productName || 'Fresh Item',
              quantity: parseFloat(i.quantity) || 1.0,
              unitPrice: parseFloat(i.unitPrice) || 0.0,
              totalPrice: (parseFloat(i.quantity) || 1.0) * (parseFloat(i.unitPrice) || 0.0)
            }))
          }
        },
        include: { items: true, vendor: true }
      });

      if (dailyTracking) {
        const existingTracking = await tx.dailyTracking.findFirst({
          where: { buyerId: profileId, vendorId: targetVendorId }
        });
        if (existingTracking) {
          await tx.dailyTracking.update({
            where: { id: existingTracking.id },
            data: { notifyOnReach, ringOnReach }
          });
        } else {
          await tx.dailyTracking.create({
            data: { buyerId: profileId, vendorId: targetVendorId, notifyOnReach, ringOnReach }
          });
        }
      }

      return newBooking;
    });

    res.json({ success: true, data: booking });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getActiveBookings = async (req, res) => {
  try {
    const { profileId } = req.user;
    const activeStatuses = ['EN_ROUTE', 'SELLER_NEARBY', 'ACCEPTED', 'PENDING'];
    
    const bookings = await prisma.booking.findMany({
      where: {
        buyerId: profileId,
        status: { in: activeStatuses }
      },
      include: {
        items: true,
        vendor: true
      },
      orderBy: { createdAt: 'desc' }
    });
    res.json({ success: true, data: bookings });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getBookingHistory = async (req, res) => {
  try {
    const { profileId } = req.user;
    const historyStatuses = ['COMPLETED', 'CANCELLED'];

    const bookings = await prisma.booking.findMany({
      where: {
        buyerId: profileId,
        status: { in: historyStatuses }
      },
      include: {
        items: true,
        vendor: true
      },
      orderBy: { createdAt: 'desc' }
    });
    res.json({ success: true, data: bookings });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getBookingDetails = async (req, res) => {
  try {
    const { profileId } = req.user;
    const { id } = req.params;

    const booking = await prisma.booking.findFirst({
      where: { id, buyerId: profileId },
      include: { items: true, vendor: true }
    });

    if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });
    res.json({ success: true, data: booking });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getBookingTracking = async (req, res) => {
  try {
    const { profileId } = req.user;
    const { id } = req.params;

    const booking = await prisma.booking.findFirst({
      where: { id, buyerId: profileId },
      include: { vendor: true }
    });

    if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

    const activeRoute = await prisma.sellingRoute.findFirst({
      where: { vendorId: booking.vendorId, isActive: true },
      include: { waypoints: { orderBy: { sequenceOrder: 'asc' } } }
    });

    res.json({
      success: true,
      data: {
        vendorLocation: {
          lat: booking.vendor.currentLatitude,
          lng: booking.vendor.currentLongitude
        },
        route: activeRoute,
        estimatedETA: '3 mins'
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.reorderBooking = async (req, res) => {
  try {
    const { profileId } = req.user;
    const { id } = req.params;

    const pastBooking = await prisma.booking.findFirst({
      where: { id, buyerId: profileId },
      include: { items: true }
    });

    if (!pastBooking) return res.status(404).json({ success: false, message: 'Booking not found' });

    const bookingNumber = `ONW-${Math.floor(10000 + Math.random() * 90000)}`;
    
    const newBooking = await prisma.booking.create({
      data: {
        bookingNumber,
        buyerId: profileId,
        vendorId: pastBooking.vendorId,
        totalAmount: pastBooking.totalAmount,
        status: 'EN_ROUTE',
        notes: pastBooking.notes,
        items: {
          create: pastBooking.items.map(i => ({
            productId: i.productId,
            productName: i.productName,
            quantity: i.quantity,
            unitPrice: i.unitPrice,
            totalPrice: i.totalPrice
          }))
        }
      },
      include: { items: true, vendor: true }
    });

    res.json({ success: true, data: newBooking });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
