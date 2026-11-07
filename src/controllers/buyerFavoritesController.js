const prisma = require('../config/prisma');

exports.getFavorites = async (req, res) => {
  try {
    const { profileId } = req.user;
    const favorites = await prisma.favorite.findMany({
      where: { buyerId: profileId },
      include: {
        vendor: true
      }
    });
    res.json({ success: true, data: favorites });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.toggleFavorite = async (req, res) => {
  try {
    const { profileId } = req.user;
    const { vendorId } = req.params;

    const existing = await prisma.favorite.findFirst({
      where: { buyerId: profileId, vendorId }
    });

    if (existing) {
      await prisma.favorite.delete({ where: { id: existing.id } });
      return res.json({ success: true, message: 'Removed from favorites' });
    } else {
      const added = await prisma.favorite.create({
        data: { buyerId: profileId, vendorId }
      });
      return res.json({ success: true, data: added, message: 'Added to favorites' });
    }
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
