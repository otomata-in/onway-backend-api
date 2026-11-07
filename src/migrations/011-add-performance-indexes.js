'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface) {
    // Optimize nearby vendor queries — index on active vendors with location
    await queryInterface.addIndex('vendors', ['is_active', 'lat', 'lng'], {
      name: 'idx_vendors_active_location',
    });

    // Optimize order lookups by status
    await queryInterface.addIndex('orders', ['vendor_id', 'status'], {
      name: 'idx_orders_vendor_status',
    });

    // Optimize buyer order history
    await queryInterface.addIndex('orders', ['buyer_id', 'created_at'], {
      name: 'idx_orders_buyer_created',
    });

    // Optimize item lookups for vendor inventory
    await queryInterface.addIndex('items', ['vendor_id', 'is_available', 'is_deleted'], {
      name: 'idx_items_vendor_available',
    });
  },

  async down(queryInterface) {
    await queryInterface.removeIndex('vendors', 'idx_vendors_active_location');
    await queryInterface.removeIndex('orders', 'idx_orders_vendor_status');
    await queryInterface.removeIndex('orders', 'idx_orders_buyer_created');
    await queryInterface.removeIndex('items', 'idx_items_vendor_available');
  },
};
