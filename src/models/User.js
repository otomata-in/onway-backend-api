const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const User = sequelize.define('User', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    mobile: {
      type: DataTypes.STRING(15),
      allowNull: false,
      unique: true,
      validate: {
        notEmpty: true,
      },
    },
    role: {
      type: DataTypes.ENUM('buyer', 'seller'),
      defaultValue: 'buyer',
      allowNull: false,
    },
    fcm_token: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
  }, {
    tableName: 'users',
    timestamps: true,
    underscored: true,
  });

  return User;
};
