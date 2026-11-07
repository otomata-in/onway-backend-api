const { Server } = require('socket.io');
const { AuthToken, User } = require('../models');

/**
 * Socket.IO singleton instance
 * Accessible throughout the app via require('./config/socket')
 */
let io = null;

/**
 * Initialize Socket.IO with the HTTP server
 * @param {http.Server} httpServer - The HTTP server instance
 * @returns {Server} Socket.IO server instance
 */
function initSocket(httpServer) {
  io = new Server(httpServer, {
    cors: {
      origin: '*', // TODO: Restrict in production
      methods: ['GET', 'POST'],
    },
    pingInterval: 25000,
    pingTimeout: 20000,
  });

  // ─── Authentication Middleware ──────────────────────────────────
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token || socket.handshake.query?.token;

      if (!token) {
        return next(new Error('Authentication token required'));
      }

      // Look up token in database
      const authToken = await AuthToken.findOne({
        where: { token },
        include: [{
          model: User,
          as: 'user',
          attributes: ['id', 'mobile', 'role'],
        }],
      });

      if (!authToken || !authToken.user) {
        return next(new Error('Invalid or expired token'));
      }

      // Attach user to socket
      socket.user = authToken.user;
      next();
    } catch (error) {
      console.error('Socket auth error:', error.message);
      next(new Error('Authentication failed'));
    }
  });

  // ─── Connection Handler ────────────────────────────────────────
  io.on('connection', (socket) => {
    const user = socket.user;
    console.log(`🔌 Socket connected: ${user.mobile} (${user.role}) [${socket.id}]`);

    // Join user-specific room
    if (user.role === 'seller') {
      // Seller joins their vendor channel for receiving orders
      socket.join(`vendor_user_${user.id}`);
    }
    // All users join their buyer channel for order updates
    socket.join(`buyer_${user.id}`);

    // ─── Seller Events ─────────────────────────────────────────
    if (user.role === 'seller') {
      // Seller sends location updates
      socket.on('location_update', (data) => {
        handleLocationUpdate(socket, user, data);
      });
    }

    // ─── Disconnect ────────────────────────────────────────────
    socket.on('disconnect', (reason) => {
      console.log(`🔌 Socket disconnected: ${user.mobile} (${reason})`);
    });

    // ─── Error Handler ─────────────────────────────────────────
    socket.on('error', (error) => {
      console.error(`Socket error [${user.mobile}]:`, error.message);
    });
  });

  console.log('✅ Socket.IO initialized');
  return io;
}

/**
 * Handle vendor location update from socket
 * - Broadcast to buyers tracking this vendor
 * - Write to Redis for real-time lookups
 * - Periodic DB sync handled separately
 */
async function handleLocationUpdate(socket, user, data) {
  const { lat, lng } = data;

  if (!lat || !lng) return;

  try {
    const { Vendor } = require('../models');
    const redis = require('./redis');

    // Find vendor
    const vendor = await Vendor.findOne({
      where: { user_id: user.id },
      attributes: ['id'],
    });

    if (!vendor) return;

    // Write to Redis (fast, for real-time reads)
    const locationKey = `vendor_location:${vendor.id}`;
    await redis.hset(locationKey, {
      lat: lat.toString(),
      lng: lng.toString(),
      updated_at: Date.now().toString(),
    });
    await redis.expire(locationKey, 3600); // Expire after 1 hour of no updates

    // Broadcast to all connected clients in vendor's broadcast room
    socket.broadcast.emit('vendor_location_update', {
      vendor_id: vendor.id,
      lat: parseFloat(lat),
      lng: parseFloat(lng),
      timestamp: new Date().toISOString(),
    });

    // Check proximity for active orders
    const proximityService = require('../utils/proximity');
    await proximityService.checkProximity(vendor.id, parseFloat(lat), parseFloat(lng));

  } catch (error) {
    console.error('Location update error:', error.message);
  }
}

/**
 * Get the Socket.IO instance
 * @returns {Server|null}
 */
function getIO() {
  return io;
}

module.exports = { initSocket, getIO };
