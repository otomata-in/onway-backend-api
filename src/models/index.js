const { Sequelize } = require('sequelize');
const config = require('../config');
const dbConfig = require('../config/database');

const env = config.nodeEnv || 'development';
const envConfig = dbConfig[env];

// Create Sequelize instance
const sequelize = new Sequelize(
  envConfig.database,
  envConfig.username,
  envConfig.password,
  {
    host: envConfig.host,
    port: envConfig.port,
    dialect: envConfig.dialect,
    logging: envConfig.logging,
    define: envConfig.define,
    pool: envConfig.pool,
  }
);

// Import models
const User = require('./User')(sequelize);
const Vendor = require('./Vendor')(sequelize);
const Item = require('./Item')(sequelize);
const Order = require('./Order')(sequelize);
const OrderItem = require('./OrderItem')(sequelize);
const AuthToken = require('./AuthToken')(sequelize);
const VendorRoute = require('./VendorRoute')(sequelize);
const VendorRoutePoint = require('./VendorRoutePoint')(sequelize);
const Favorite = require('./Favorite')(sequelize);

// ─── Associations ────────────────────────────────────────────────

// User <-> Vendor (one-to-one)
User.hasOne(Vendor, { foreignKey: 'user_id', as: 'vendor' });
Vendor.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// User <-> AuthToken (one-to-many)
User.hasMany(AuthToken, { foreignKey: 'user_id', as: 'authTokens' });
AuthToken.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// Vendor <-> Item (one-to-many)
Vendor.hasMany(Item, { foreignKey: 'vendor_id', as: 'items' });
Item.belongsTo(Vendor, { foreignKey: 'vendor_id', as: 'vendor' });

// User (buyer) <-> Order (one-to-many)
User.hasMany(Order, { foreignKey: 'buyer_id', as: 'buyerOrders' });
Order.belongsTo(User, { foreignKey: 'buyer_id', as: 'buyer' });

// Vendor <-> Order (one-to-many)
Vendor.hasMany(Order, { foreignKey: 'vendor_id', as: 'orders' });
Order.belongsTo(Vendor, { foreignKey: 'vendor_id', as: 'vendor' });

// Order <-> OrderItem (one-to-many)
Order.hasMany(OrderItem, { foreignKey: 'order_id', as: 'orderItems' });
OrderItem.belongsTo(Order, { foreignKey: 'order_id', as: 'order' });

// Item <-> OrderItem (one-to-many)
Item.hasMany(OrderItem, { foreignKey: 'item_id', as: 'orderItems' });
OrderItem.belongsTo(Item, { foreignKey: 'item_id', as: 'item' });

// Vendor <-> VendorRoute (one-to-many)
Vendor.hasMany(VendorRoute, { foreignKey: 'vendor_id', as: 'routes' });
VendorRoute.belongsTo(Vendor, { foreignKey: 'vendor_id', as: 'vendor' });

// Vendor -> current active route (belongs-to)
Vendor.belongsTo(VendorRoute, { foreignKey: 'current_route_id', as: 'currentRoute' });

// VendorRoute <-> VendorRoutePoint (one-to-many)
VendorRoute.hasMany(VendorRoutePoint, { foreignKey: 'route_id', as: 'points' });
VendorRoutePoint.belongsTo(VendorRoute, { foreignKey: 'route_id', as: 'route' });

// User <-> Favorite (one-to-many)
User.hasMany(Favorite, { foreignKey: 'user_id', as: 'favorites' });
Favorite.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// Vendor <-> Favorite (one-to-many)
Vendor.hasMany(Favorite, { foreignKey: 'vendor_id', as: 'favoritedBy' });
Favorite.belongsTo(Vendor, { foreignKey: 'vendor_id', as: 'vendor' });

// ─── Export ──────────────────────────────────────────────────────

const db = {
  sequelize,
  Sequelize,
  User,
  Vendor,
  Item,
  Order,
  OrderItem,
  AuthToken,
  VendorRoute,
  VendorRoutePoint,
  Favorite,
};

module.exports = db;
