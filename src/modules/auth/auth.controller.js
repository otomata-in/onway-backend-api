const authService = require('./auth.service');
const ApiResponse = require('../../utils/ApiResponse');

const authController = {
  /**
   * POST /auth/send-otp
   * Send OTP to mobile number
   */
  async sendOtp(req, res, next) {
    try {
      const { mobile } = req.body;
      const result = await authService.sendOtp(mobile);
      return ApiResponse.success(res, result, 'OTP sent successfully');
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /auth/verify-otp
   * Verify OTP and return auth token
   */
  async verifyOtp(req, res, next) {
    try {
      const { mobile, otp } = req.body;
      const result = await authService.verifyOtp(mobile, otp);
      return ApiResponse.success(res, result, 'OTP verified successfully');
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /auth/logout
   * Invalidate auth token
   */
  async logout(req, res, next) {
    try {
      const result = await authService.logout(req.token);
      return ApiResponse.success(res, result, 'Logged out successfully');
    } catch (error) {
      next(error);
    }
  },
};

module.exports = authController;
