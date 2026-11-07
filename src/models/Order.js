const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Order = sequelize.define('Order', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    buyer_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id',
      },
    },
    vendor_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'vendors',
        key: 'id',
      },
    },
    status: {
      type: DataTypes.ENUM('requested', 'accepted', 'rejected', 'fulfilled', 'expired'),
      defaultValue: 'requested',
      allowNull: false,
    },
    type: {
      type: DataTypes.STRING(20),
      defaultValue: 'token',
    },
    buyer_lat: {
      type: DataTypes.DECIMAL(10, 8),
      allowNull: true,
    },
    buyer_lng: {
      type: DataTypes.DECIMAL(11, 8),
      allowNull: true,
    },
    has_entered_zone: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    expired_at: {
      type: DataTypes.DATE,
      allowNull: true,
    },
  }, {
    tableName: 'orders',
    timestamps: true,
    underscored: true,
  });

  return Order;
};
