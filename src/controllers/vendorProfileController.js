const prisma = require('../config/prisma');

async function getProfile(req, res) {
  try {
    const { profileId } = req.user;
    const vendorProfile = await prisma.vendorProfile.findUnique({
      where: { id: profileId },
      include: {
        user: { select: { phone: true } },
        sellingRoutes: {
          where: { isActive: true },
          include: { waypoints: { orderBy: { sequenceOrder: 'asc' } } }
        }
      }
    });
    
    if (!vendorProfile) {
      return res.status(404).json({ success: false, message: 'Profile not found' });
    }
    
    const productCount = await prisma.inventoryProduct.count({
      where: { vendorId: profileId, isDeleted: false }
    });

    return res.json({ success: true, data: { ...vendorProfile, productCount } });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

async function updateProfile(req, res) {
  try {
    const { profileId } = req.user;
    const { businessName, category, vehicleNumber } = req.body;
    
    const updated = await prisma.vendorProfile.update({
      where: { id: profileId },
      data: { businessName, category, vehicleNumber }
    });
    
    return res.json({ success: true, data: updated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

async function updateOperatingHours(req, res) {
  try {
    const { profileId } = req.user;
    const { operatingHours } = req.body;
    
    const updated = await prisma.vendorProfile.update({
      where: { id: profileId },
      data: { operatingHours }
    });
    
    return res.json({ success: true, data: updated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

async function uploadVehicleImage(req, res) {
  try {
    const { profileId } = req.user;
    const { vehicleImagePath } = req.body;
    
    const updated = await prisma.vendorProfile.update({
      where: { id: profileId },
      data: { vehicleImagePath }
    });
    
    return res.json({ success: true, data: updated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

async function getQrData(req, res) {
  try {
    const { profileId } = req.user;
    const vendorProfile = await prisma.vendorProfile.findUnique({
      where: { id: profileId }
    });
    
    if (!vendorProfile) {
      return res.status(404).json({ success: false, message: 'Profile not found' });
    }
    
    const qrPayload = `ONWAY_VENDOR:${vendorProfile.businessName}|${vendorProfile.vehicleNumber}`;
    return res.json({ success: true, data: { qrPayload } });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

module.exports = {
  getProfile,
  updateProfile,
  updateOperatingHours,
  uploadVehicleImage,
  getQrData
};
