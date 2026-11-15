const jwt = require('jsonwebtoken');
const prisma = require('../config/prisma');

function initSocket(io) {
  // Authentication middleware for socket connections
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token || socket.handshake.query?.token;
      if (token) {
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'teritory_secret');
        const user = await prisma.user.findUnique({ where: { id: decoded.sub || decoded.id } });
        if (user) {
          socket.user = user;
        }
      }
      next();
    } catch (err) {
      // Allow unauthenticated connection or proceed
      next();
    }
  });

  io.on('connection', (socket) => {
    const user = socket.user;
    if (user) {
      socket.join(`user:${user.id}`);
      console.log(`🔌 Teritory Socket connected: ${user.displayName} (${socket.id})`);
    } else {
      console.log(`🔌 Teritory Socket connected (Guest): (${socket.id})`);
    }

    // Community Chat Room
    socket.on('join_community', (data) => {
      const { communityId } = data;
      if (communityId) {
        socket.join(`community:${communityId}`);
      }
    });

    socket.on('leave_community', (data) => {
      const { communityId } = data;
      if (communityId) {
        socket.leave(`community:${communityId}`);
      }
    });

    socket.on('chat_typing', (data) => {
      const { communityId, isTyping } = data;
      if (communityId && user) {
        socket.to(`community:${communityId}`).emit('user_typing', {
          communityId,
          userId: user.id,
          displayName: user.displayName,
          isTyping,
        });
      }
    });

    // Active Trip Room
    socket.on('join_trip', (data) => {
      const { tripId } = data;
      if (tripId) {
        socket.join(`trip:${tripId}`);
      }
    });

    socket.on('trip_location_update', (data) => {
      const { tripId, latitude, longitude } = data;
      if (tripId && user) {
        socket.to(`trip:${tripId}`).emit('participant_location', {
          tripId,
          userId: user.id,
          displayName: user.displayName,
          latitude,
          longitude,
          timestamp: new Date(),
        });
      }
    });

    // Legendary Rally Room
    socket.on('join_rally', (data) => {
      const { rallyId } = data;
      if (rallyId) {
        socket.join(`rally:${rallyId}`);
      }
    });

    socket.on('disconnect', () => {
      if (user) {
        console.log(`🔌 Teritory Socket disconnected: ${user.displayName}`);
      }
    });
  });

  return io;
}

module.exports = { initSocket };
