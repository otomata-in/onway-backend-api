const { User, Vendor } = require('../../models');
const ApiError = require('../../utils/ApiError');

const userService = {
  /**
   * Get current user profile
   * Includes vendor info if user is a seller
   */
  async getMe(userId) {
    const user = await User.findByPk(userId, {
      attributes: ['id', 'mobile', 'role', 'fcm_token', 'created_at'],
      include: [{
        model: Vendor,
        as: 'vendor',
        attributes: ['id', 'is_active', 'lat', 'lng'],
        required: false,  // LEFT JOIN — include even if no vendor record
      }],
    });

    if (!user) {
      throw ApiError.notFound('User not found');
    }

    return user;
  },

  /**
   * Save/update FCM token for push notifications
   */
  async saveFcmToken(userId, fcmToken) {
    const user = await User.findByPk(userId);

    if (!user) {
      throw ApiError.notFound('User not found');
    }

    user.fcm_token = fcmToken;
    await user.save();

    return { message: 'FCM token saved successfully' };
  },

  /**
   * Update user's location (buyer's home/preferred location)
   * For vendors, location is updated via the vendor location endpoint
   */
  async updateLocation(userId, lat, lng) {
    const user = await User.findByPk(userId);

    if (!user) {
      throw ApiError.notFound('User not found');
    }

    // If user is a seller, update vendor location
    if (user.role === 'seller') {
      const vendor = await Vendor.findOne({ where: { user_id: userId } });
      if (vendor) {
        vendor.lat = lat;
        vendor.lng = lng;
        await vendor.save();
      }
    }

    return { message: 'Location updated successfully' };
  },
};

module.exports = userService;
