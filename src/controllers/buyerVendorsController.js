const prisma = require('../config/prisma');

function haversineDistance(lat1, lng1, lat2, lng2) {
  const R = 6371000;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng/2) * Math.sin(dLng/2);
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
}

exports.getNearbyVendors = async (req, res) => {
  try {
    const { lat, lng, category, q, radius = 50000 } = req.query;
    const profileId = req.user ? req.user.profileId : null;

    const vendors = await prisma.vendorProfile.findMany({
      where: {
        isLiveBroadcasting: true,
        ...(category && category !== 'All' && { category: { contains: category, mode: 'insensitive' } }),
        ...(q && { businessName: { contains: q, mode: 'insensitive' } })
      },
      include: {
        favoritedBy: profileId ? {
          where: { buyerId: profileId }
        } : false
      }
    });

    const latNum = parseFloat(lat) || 10.59337;
    const lngNum = parseFloat(lng) || 76.080334;
    const radNum = parseFloat(radius) || 50000;

    const nearby = vendors.map(vendor => {
      const vLat = vendor.currentLatitude || 10.59337;
      const vLng = vendor.currentLongitude || 76.080334;
      const distance = haversineDistance(latNum, lngNum, vLat, vLng);
      return {
        ...vendor,
        currentLatitude: vLat,
        currentLongitude: vLng,
        distance,
        isFavorite: Array.isArray(vendor.favoritedBy) && vendor.favoritedBy.length > 0
      };
    }).filter(v => v.distance <= radNum).sort((a, b) => a.distance - b.distance);

    res.json({ success: true, data: nearby });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getLiveMapVendors = async (req, res) => {
  try {
    const vendors = await prisma.vendorProfile.findMany({
      where: { isLiveBroadcasting: true },
      select: {
        id: true,
        businessName: true,
        category: true,
        currentLatitude: true,
        currentLongitude: true,
        vehicleImagePath: true
      }
    });
    res.json({ success: true, data: vendors });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getVendorDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const profileId = req.user ? req.user.profileId : null;
    
    const vendor = await prisma.vendorProfile.findUnique({
      where: { id },
      include: {
        sellingRoutes: {
          where: { isActive: true },
          include: { waypoints: { orderBy: { sequenceOrder: 'asc' } } }
        },
        favoritedBy: profileId ? {
          where: { buyerId: profileId }
        } : false
      }
    });

    if (!vendor) return res.status(404).json({ success: false, message: 'Vendor not found' });
    
    const isFavorite = Array.isArray(vendor.favoritedBy) && vendor.favoritedBy.length > 0;
    res.json({ success: true, data: { ...vendor, isFavorite } });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getVendorProducts = async (req, res) => {
  try {
    const { id } = req.params;
    const products = await prisma.inventoryProduct.findMany({
      where: {
        vendorId: id,
        isDeleted: false,
        inStock: true
      }
    });
    res.json({ success: true, data: products });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getVendorRoute = async (req, res) => {
  try {
    const { id } = req.params;

    let targetVendorId = id;
    if (id && (id.length < 20 || !id.includes('-'))) {
      const v = await prisma.vendorProfile.findFirst({
        where: { businessName: { contains: id, mode: 'insensitive' } }
      });
      if (v) targetVendorId = v.id;
    }

    let activeRoute = await prisma.sellingRoute.findFirst({
      where: { vendorId: targetVendorId, isActive: true },
      include: {
        waypoints: {
          orderBy: { sequenceOrder: 'asc' }
        }
      }
    });

    if (!activeRoute) {
      activeRoute = await prisma.sellingRoute.findFirst({
        where: { vendorId: targetVendorId },
        include: { waypoints: { orderBy: { sequenceOrder: 'asc' } } }
      });
    }

    if (!activeRoute) {
      activeRoute = await prisma.sellingRoute.findFirst({
        include: { waypoints: { orderBy: { sequenceOrder: 'asc' } } }
      });
    }

    res.json({ success: true, data: activeRoute });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getVendorETA = async (req, res) => {
  try {
    const { id } = req.params;
    const { lat, lng } = req.query;

    const vendor = await prisma.vendorProfile.findUnique({ where: { id } });
    if (!vendor) {
      return res.status(404).json({ success: false, message: 'Vendor not found' });
    }

    const latNum = parseFloat(lat) || 10.59337;
    const lngNum = parseFloat(lng) || 76.080334;
    const vLat = vendor.currentLatitude || 10.59337;
    const vLng = vendor.currentLongitude || 76.080334;
    
    const distance = haversineDistance(latNum, lngNum, vLat, vLng);
    const etaSeconds = distance / 5.55;

    res.json({ success: true, data: { distance, etaSeconds, etaMinutes: Math.ceil(etaSeconds/60) } });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.scanQr = async (req, res) => {
  try {
    const { qrCode } = req.body;
    if (!qrCode || !qrCode.startsWith('ONWAY_VENDOR:')) {
      return res.status(400).json({ success: false, message: 'Invalid QR format' });
    }
    const parts = qrCode.replace('ONWAY_VENDOR:', '').split('|');
    const vehicleNumber = parts[1];

    const vendor = await prisma.vendorProfile.findFirst({
      where: { vehicleNumber },
      include: { products: { where: { isDeleted: false, inStock: true } } }
    });

    if (!vendor) return res.status(404).json({ success: false, message: 'Vendor not found' });
    res.json({ success: true, data: vendor });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getCategories = async (req, res) => {
  try {
    const categories = await prisma.vendorProfile.findMany({
      select: { category: true },
      distinct: ['category']
    });
    res.json({ success: true, data: categories.map(c => c.category) });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
