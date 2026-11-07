const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const VendorRoutePoint = sequelize.define('VendorRoutePoint', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    route_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'vendor_routes',
        key: 'id',
      },
    },
    lat: {
      type: DataTypes.DECIMAL(10, 8),
      allowNull: false,
    },
    lng: {
      type: DataTypes.DECIMAL(11, 8),
      allowNull: false,
    },
    sequence: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
  }, {
    tableName: 'vendor_route_points',
    timestamps: false,
    underscored: true,
  });

  return VendorRoutePoint;
};
