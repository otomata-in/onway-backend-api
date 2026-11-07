const inventoryService = require('./inventory.service');
const ApiResponse = require('../../utils/ApiResponse');

const inventoryController = {
  /**
   * GET /seller/items
   * Get all items for the authenticated seller
   */
  async getItems(req, res, next) {
    try {
      const items = await inventoryService.getItems(req.user.id);
      return ApiResponse.success(res, items, 'Items retrieved');
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /seller/items
   * Add a new item
   */
  async addItem(req, res, next) {
    try {
      const item = await inventoryService.addItem(req.user.id, req.body);
      return ApiResponse.created(res, item, 'Item added successfully');
    } catch (error) {
      next(error);
    }
  },

  /**
   * PUT /seller/items/:id
   * Update an item
   */
  async updateItem(req, res, next) {
    try {
      const item = await inventoryService.updateItem(req.user.id, req.params.id, req.body);
      return ApiResponse.success(res, item, 'Item updated successfully');
    } catch (error) {
      next(error);
    }
  },

  /**
   * DELETE /seller/items/:id
   * Soft delete an item
   */
  async deleteItem(req, res, next) {
    try {
      const result = await inventoryService.deleteItem(req.user.id, req.params.id);
      return ApiResponse.success(res, result, 'Item deleted successfully');
    } catch (error) {
      next(error);
    }
  },
};

module.exports = inventoryController;
