const userService = require('./user.service');
const ApiResponse = require('../../utils/ApiResponse');

const userController = {
  /**
   * GET /me
   * Get current authenticated user's profile
   */
  async getMe(req, res, next) {
    try {
      const user = await userService.getMe(req.user.id);
      return ApiResponse.success(res, user, 'User profile retrieved');
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /users/fcm-token
   * Save FCM token for push notifications
   */
  async saveFcmToken(req, res, next) {
    try {
      const { token } = req.body;
      const result = await userService.saveFcmToken(req.user.id, token);
      return ApiResponse.success(res, result, 'FCM token saved');
    } catch (error) {
      next(error);
    }
  },

  /**
   * PUT /me/location
   * Update user's location
   */
  async updateLocation(req, res, next) {
    try {
      const { lat, lng } = req.body;
      const result = await userService.updateLocation(req.user.id, lat, lng);
      return ApiResponse.success(res, result, 'Location updated');
    } catch (error) {
      next(error);
    }
  },
};

module.exports = userController;
