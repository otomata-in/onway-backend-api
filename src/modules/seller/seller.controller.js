const sellerService = require('./seller.service');
const ApiResponse = require('../../utils/ApiResponse');

const sellerController = {
  /**
   * POST /seller/register
   * Register current user as a seller
   */
  async register(req, res, next) {
    try {
      const { vehicle_name } = req.body;
      const result = await sellerService.register(req.user.id, vehicle_name);
      return ApiResponse.created(res, result, 'Registered as seller successfully');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /seller/dashboard
   * Get seller dashboard data
   */
  async getDashboard(req, res, next) {
    try {
      const result = await sellerService.getDashboard(req.user.id);
      return ApiResponse.success(res, result, 'Dashboard data retrieved');
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /vendors/status
   * Toggle selling status
   */
  async toggleStatus(req, res, next) {
    try {
      const { is_active } = req.body;
      const result = await sellerService.toggleStatus(req.user.id, is_active);
      return ApiResponse.success(res, result, `Selling ${is_active ? 'started' : 'stopped'}`);
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /vendors/location
   * Update vendor location
   */
  async updateLocation(req, res, next) {
    try {
      const { lat, lng } = req.body;
      const result = await sellerService.updateLocation(req.user.id, lat, lng);
      return ApiResponse.success(res, result, 'Location updated');
    } catch (error) {
      next(error);
    }
  },
};

module.exports = sellerController;
