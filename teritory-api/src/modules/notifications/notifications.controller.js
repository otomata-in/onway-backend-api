const prisma = require('../../config/prisma');
const ApiResponse = require('../../utils/ApiResponse');

const getNotifications = async (req, res, next) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return ApiResponse.success(res, notifications);
  } catch (err) {
    next(err);
  }
};

const markRead = async (req, res, next) => {
  try {
    const { id } = req.params;
    await prisma.notification.updateMany({
      where: { id, userId: req.user.id },
      data: { isRead: true },
    });
    return ApiResponse.success(res, { read: true });
  } catch (err) {
    next(err);
  }
};

const markAllRead = async (req, res, next) => {
  try {
    await prisma.notification.updateMany({
      where: { userId: req.user.id, isRead: false },
      data: { isRead: true },
    });
    return ApiResponse.success(res, { allRead: true });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getNotifications,
  markRead,
  markAllRead,
};

