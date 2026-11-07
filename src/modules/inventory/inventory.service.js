const { Item, Vendor } = require('../../models');
const ApiError = require('../../utils/ApiError');

const inventoryService = {
  /**
   * Get the vendor record for a user, or throw
   */
  async _getVendor(userId) {
    const vendor = await Vendor.findOne({ where: { user_id: userId } });
    if (!vendor) {
      throw ApiError.notFound('Vendor profile not found', 'VENDOR_NOT_FOUND');
    }
    return vendor;
  },

  /**
   * Get all items for the authenticated seller
   */
  async getItems(userId) {
    const vendor = await this._getVendor(userId);

    const items = await Item.findAll({
      where: { vendor_id: vendor.id },
      order: [['created_at', 'DESC']],
      attributes: ['id', 'name', 'price', 'quantity', 'is_available', 'created_at', 'updated_at'],
    });

    return items;
  },

  /**
   * Add a new item to inventory
   */
  async addItem(userId, itemData) {
    const vendor = await this._getVendor(userId);

    const item = await Item.create({
      vendor_id: vendor.id,
      name: itemData.name,
      price: itemData.price,
      quantity: itemData.quantity || 0,
      is_available: itemData.is_available !== undefined ? itemData.is_available : true,
    });

    return {
      id: item.id,
      name: item.name,
      price: item.price,
      quantity: item.quantity,
      is_available: item.is_available,
    };
  },

  /**
   * Update an existing item
   * Ensures the item belongs to the authenticated seller
   */
  async updateItem(userId, itemId, updateData) {
    const vendor = await this._getVendor(userId);

    const item = await Item.findOne({
      where: { id: itemId, vendor_id: vendor.id },
    });

    if (!item) {
      throw ApiError.notFound('Item not found', 'ITEM_NOT_FOUND');
    }

    // Update only provided fields
    if (updateData.name !== undefined) item.name = updateData.name;
    if (updateData.price !== undefined) item.price = updateData.price;
    if (updateData.quantity !== undefined) item.quantity = updateData.quantity;
    if (updateData.is_available !== undefined) item.is_available = updateData.is_available;

    await item.save();

    return {
      id: item.id,
      name: item.name,
      price: item.price,
      quantity: item.quantity,
      is_available: item.is_available,
    };
  },

  /**
   * Soft delete an item
   * Sets is_deleted = true instead of removing from DB
   */
  async deleteItem(userId, itemId) {
    const vendor = await this._getVendor(userId);

    const item = await Item.findOne({
      where: { id: itemId, vendor_id: vendor.id },
    });

    if (!item) {
      throw ApiError.notFound('Item not found', 'ITEM_NOT_FOUND');
    }

    item.is_deleted = true;
    item.is_available = false;
    await item.save();

    return { message: 'Item deleted successfully' };
  },
};

module.exports = inventoryService;
