const vendorService = require('./vendor.service');
const ApiResponse = require('../../utils/ApiResponse');

const vendorController = {
  /**
   * GET /vendors/nearby?lat=&lng=&radius=
   * Find nearby active vendors
   */
  async getNearby(req, res, next) {
    try {
      const { lat, lng, radius } = req.query;
      const vendors = await vendorService.getNearby(
        parseFloat(lat),
        parseFloat(lng),
        parseFloat(radius)
      );
      return ApiResponse.success(res, vendors, `Found ${vendors.length} nearby vendors`);
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /vendors/:id
   * Get vendor details
   */
  async getVendorDetails(req, res, next) {
    try {
      const vendor = await vendorService.getVendorDetails(req.params.id);
      return ApiResponse.success(res, vendor, 'Vendor details retrieved');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /vendors/:id/items
   * Get vendor's available items
   */
  async getVendorItems(req, res, next) {
    try {
      const items = await vendorService.getVendorItems(req.params.id);
      return ApiResponse.success(res, items, 'Vendor items retrieved');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /vendors/:id/eta?lat=&lng=
   * Get ETA for vendor to reach buyer's location
   */
  async getVendorETA(req, res, next) {
    try {
      const eta = await vendorService.getVendorETA(
        req.params.id,
        parseFloat(req.query.lat),
        parseFloat(req.query.lng)
      );
      return ApiResponse.success(res, eta, 'ETA calculated');
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /vendors/:id/favorite
   * Toggle favorite vendor
   */
  async toggleFavorite(req, res, next) {
    try {
      const result = await vendorService.toggleFavorite(req.user.id, req.params.id);
      const message = result.favorited ? 'Vendor added to favorites' : 'Vendor removed from favorites';
      return ApiResponse.success(res, result, message);
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /vendors/favorites
   * Get user's favorite vendors
   */
  async getFavorites(req, res, next) {
    try {
      const favorites = await vendorService.getFavorites(req.user.id);
      return ApiResponse.success(res, favorites, 'Favorites retrieved');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /admin/active-vendors
   * Get all currently active vendors (admin)
   */
  async getActiveVendors(req, res, next) {
    try {
      const result = await vendorService.getActiveVendors();
      return ApiResponse.success(res, result, `${result.count} active vendors`);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = vendorController;
