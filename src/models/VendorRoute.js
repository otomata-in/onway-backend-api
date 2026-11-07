const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const VendorRoute = sequelize.define('VendorRoute', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    vendor_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'vendors',
        key: 'id',
      },
    },
    name: {
      type: DataTypes.STRING(100),
      allowNull: false,
      validate: {
        notEmpty: true,
      },
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
  }, {
    tableName: 'vendor_routes',
    timestamps: true,
    underscored: true,
  });

  return VendorRoute;
};
