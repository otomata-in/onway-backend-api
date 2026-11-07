const prisma = require('../config/prisma');

exports.getDailyTrackings = async (req, res) => {
  try {
    const { profileId } = req.user;
    const trackings = await prisma.dailyTracking.findMany({
      where: { buyerId: profileId },
      include: {
        vendor: true
      }
    });
    res.json({ success: true, data: trackings });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.updateTrackingPreferences = async (req, res) => {
  try {
    const { profileId } = req.user;
    const { vendorId } = req.params;
    const { notifyOnReach, ringOnReach } = req.body;

    const existing = await prisma.dailyTracking.findFirst({
      where: { buyerId: profileId, vendorId }
    });

    if (existing) {
      const updated = await prisma.dailyTracking.update({
        where: { id: existing.id },
        data: { notifyOnReach, ringOnReach }
      });
      return res.json({ success: true, data: updated });
    } else {
      const created = await prisma.dailyTracking.create({
        data: {
          buyerId: profileId,
          vendorId,
          notifyOnReach: notifyOnReach !== undefined ? notifyOnReach : true,
          ringOnReach: ringOnReach !== undefined ? ringOnReach : false
        }
      });
      return res.json({ success: true, data: created });
    }
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.removeTracking = async (req, res) => {
  try {
    const { profileId } = req.user;
    const { vendorId } = req.params;

    const existing = await prisma.dailyTracking.findFirst({
      where: { buyerId: profileId, vendorId }
    });

    if (!existing) {
      return res.status(404).json({ success: false, message: 'Tracking not found' });
    }

    await prisma.dailyTracking.delete({ where: { id: existing.id } });
    res.json({ success: true, message: 'Tracking removed' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
