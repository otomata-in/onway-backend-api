const prisma = require('../config/prisma');

exports.getProfile = async (req, res) => {
  try {
    const { profileId } = req.user;
    const profile = await prisma.buyerProfile.findUnique({
      where: { id: profileId },
      include: { user: true }
    });
    res.json({ success: true, data: profile });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const { profileId } = req.user;
    const { fullName, email, avatarUrl } = req.body;
    
    const dataToUpdate = {};
    if (fullName !== undefined) dataToUpdate.fullName = fullName;
    if (email !== undefined) dataToUpdate.email = email;
    if (avatarUrl !== undefined) dataToUpdate.avatarUrl = avatarUrl;

    const updated = await prisma.buyerProfile.update({
      where: { id: profileId },
      data: dataToUpdate,
      include: { user: true }
    });
    res.json({ success: true, data: updated });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.uploadAvatar = async (req, res) => {
  try {
    const { profileId } = req.user;
    const { avatarUrl } = req.body;
    const updated = await prisma.buyerProfile.update({
      where: { id: profileId },
      data: { avatarUrl },
      include: { user: true }
    });
    res.json({ success: true, data: updated });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getPreferences = async (req, res) => {
  try {
    const { profileId } = req.user;
    const profile = await prisma.buyerProfile.findUnique({
      where: { id: profileId },
      select: { pushNotifications: true, darkMode: true, language: true }
    });
    res.json({ success: true, data: profile });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.updatePreferences = async (req, res) => {
  try {
    const { profileId } = req.user;
    const { pushNotifications, darkMode, language } = req.body;
    
    const dataToUpdate = {};
    if (pushNotifications !== undefined) dataToUpdate.pushNotifications = pushNotifications;
    if (darkMode !== undefined) dataToUpdate.darkMode = darkMode;
    if (language !== undefined) dataToUpdate.language = language;

    const updated = await prisma.buyerProfile.update({
      where: { id: profileId },
      data: dataToUpdate
    });
    res.json({ success: true, data: updated });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
