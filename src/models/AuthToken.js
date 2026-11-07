const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const AuthToken = sequelize.define('AuthToken', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id',
      },
    },
    token: {
      type: DataTypes.STRING(255),
      allowNull: false,
      unique: true,
    },
  }, {
    tableName: 'auth_tokens',
    timestamps: true,
    underscored: true,
  });

  return AuthToken;
};
