'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    // Add foreign key from vendors.current_route_id to vendor_routes.id
    await queryInterface.addConstraint('vendors', {
      fields: ['current_route_id'],
      type: 'foreign key',
      name: 'fk_vendors_current_route',
      references: {
        table: 'vendor_routes',
        field: 'id',
      },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL',
    });
  },

  async down(queryInterface) {
    await queryInterface.removeConstraint('vendors', 'fk_vendors_current_route');
  },
};
