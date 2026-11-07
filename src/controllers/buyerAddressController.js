const prisma = require('../config/prisma');

exports.getAddresses = async (req, res) => {
  try {
    const { profileId } = req.user;
    const addresses = await prisma.buyerAddress.findMany({
      where: { buyerId: profileId },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: addresses });
  } catch (error) {
    console.error('Error in getAddresses:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.addAddress = async (req, res) => {
  try {
    const { profileId } = req.user;
    const {
      title,
      label,
      addressLine,
      street,
      deliveryInstructions,
      latitude,
      lat,
      longitude,
      lng,
      isDefault = false,
    } = req.body;

    const finalTitle = title || label || 'Home';
    const finalAddressLine = addressLine || street || '';
    const finalLat = parseFloat(latitude ?? lat ?? 9.9790);
    const finalLng = parseFloat(longitude ?? lng ?? 76.2760);

    if (isDefault) {
      await prisma.buyerAddress.updateMany({
        where: { buyerId: profileId },
        data: { isDefault: false },
      });
    }

    const address = await prisma.buyerAddress.create({
      data: {
        buyerId: profileId,
        title: finalTitle,
        addressLine: finalAddressLine,
        deliveryInstructions,
        latitude: finalLat,
        longitude: finalLng,
        isDefault,
      },
    });
    res.json({ success: true, data: address });
  } catch (error) {
    console.error('Error in addAddress:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.updateAddress = async (req, res) => {
  try {
    const { profileId } = req.user;
    const { id } = req.params;
    const {
      title,
      label,
      addressLine,
      street,
      deliveryInstructions,
      latitude,
      lat,
      longitude,
      lng,
      isDefault,
    } = req.body;

    const existing = await prisma.buyerAddress.findFirst({
      where: { id, buyerId: profileId },
    });
    if (!existing) {
      return res.status(404).json({ success: false, message: 'Address not found' });
    }

    if (isDefault) {
      await prisma.buyerAddress.updateMany({
        where: { buyerId: profileId },
        data: { isDefault: false },
      });
    }

    const updateData = {};
    if (title !== undefined || label !== undefined) updateData.title = title || label;
    if (addressLine !== undefined || street !== undefined) updateData.addressLine = addressLine || street;
    if (deliveryInstructions !== undefined) updateData.deliveryInstructions = deliveryInstructions;
    if (latitude !== undefined || lat !== undefined) updateData.latitude = parseFloat(latitude ?? lat);
    if (longitude !== undefined || lng !== undefined) updateData.longitude = parseFloat(longitude ?? lng);
    if (isDefault !== undefined) updateData.isDefault = isDefault;

    const updated = await prisma.buyerAddress.update({
      where: { id },
      data: updateData,
    });
    res.json({ success: true, data: updated });
  } catch (error) {
    console.error('Error in updateAddress:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.deleteAddress = async (req, res) => {
  try {
    const { profileId } = req.user;
    const { id } = req.params;

    const existing = await prisma.buyerAddress.findFirst({
      where: { id, buyerId: profileId },
    });
    if (!existing) {
      return res.status(404).json({ success: false, message: 'Address not found' });
    }

    await prisma.buyerAddress.delete({ where: { id } });
    res.json({ success: true, message: 'Address deleted successfully' });
  } catch (error) {
    console.error('Error in deleteAddress:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};
