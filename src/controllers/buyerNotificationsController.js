const prisma = require('../config/prisma');

exports.getNotifications = async (req, res) => {
  try {
    const { profileId } = req.user;
    const notifications = await prisma.notification.findMany({
      where: { profileId },
      orderBy: { createdAt: 'desc' }
    });

    const today = [];
    const earlier = [];
    const now = new Date();

    notifications.forEach(n => {
      const isToday = n.createdAt.getDate() === now.getDate() &&
        n.createdAt.getMonth() === now.getMonth() &&
        n.createdAt.getFullYear() === now.getFullYear();
      if (isToday) today.push(n);
      else earlier.push(n);
    });

    res.json({ success: true, data: { today, earlier } });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.markAsRead = async (req, res) => {
  try {
    const { profileId } = req.user;
    const { id } = req.body;

    if (id) {
      const updated = await prisma.notification.updateMany({
        where: { id, profileId },
        data: { isRead: true }
      });
      res.json({ success: true, data: updated });
    } else {
      const updated = await prisma.notification.updateMany({
        where: { profileId, isRead: false },
        data: { isRead: true }
      });
      res.json({ success: true, data: updated });
    }
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
