'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('orders', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
        allowNull: false,
      },
      buyer_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      vendor_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'vendors',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      status: {
        type: Sequelize.ENUM('requested', 'accepted', 'rejected', 'fulfilled', 'expired'),
        defaultValue: 'requested',
        allowNull: false,
      },
      type: {
        type: Sequelize.STRING(20),
        defaultValue: 'token',
      },
      buyer_lat: {
        type: Sequelize.DECIMAL(10, 8),
        allowNull: true,
      },
      buyer_lng: {
        type: Sequelize.DECIMAL(11, 8),
        allowNull: true,
      },
      has_entered_zone: {
        type: Sequelize.BOOLEAN,
        defaultValue: false,
      },
      expired_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'),
      },
    });

    // Indexes for common queries
    await queryInterface.addIndex('orders', ['buyer_id', 'status']);
    await queryInterface.addIndex('orders', ['vendor_id', 'status']);
  },

  async down(queryInterface) {
    await queryInterface.dropTable('orders');
  },
};
