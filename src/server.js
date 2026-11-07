const http = require('http');
const app = require('./app');
const prisma = require('./config/prisma');
const redis = require('./config/redis');
const config = require('./config');
const { initSocket } = require('./config/socket');
const { initFirebase } = require('./utils/fcm');
const locationSync = require('./utils/locationSync');

const PORT = config.port;

/**
 * Start the server
 * 1. Test database connection
 * 2. Connect to Redis
 * 3. Start HTTP + Socket.IO server
 */
async function startServer() {
  try {
    // Test Neon PostgreSQL connection via Prisma
    await prisma.$queryRaw`SELECT 1`;
    console.log('✅ Neon PostgreSQL (Prisma) connected successfully');

    // Connect to Redis (optional — degrades gracefully)
    try {
      await redis.connect();
      console.log('✅ Redis connected successfully');
    } catch (redisErr) {
      console.warn('⚠️  Redis not available — running without cache. Location caching disabled.');
    }

    // Initialize Firebase (FCM push notifications)
    initFirebase();

    // Create HTTP server and attach Socket.IO
    const server = http.createServer(app);
    initSocket(server);

    // Start listening
    server.listen(PORT, () => {
      console.log('');
      console.log('┌─────────────────────────────────────────┐');
      console.log(`│  🚀 OnWay API Server                    │`);
      console.log(`│  Port: ${PORT}                              │`);
      console.log(`│  Env:  ${config.nodeEnv.padEnd(33)}│`);
      console.log(`│  Socket.IO: enabled                     │`);
      console.log(`│  Batch sync: 30s                        │`);
      console.log('└─────────────────────────────────────────┘');
      console.log('');

      // Start batch location sync (Redis → MySQL) (Disabled for now)
      // locationSync.start();
    });

    // Graceful shutdown
    const gracefulShutdown = async (signal) => {
      console.log(`\n⚠️  ${signal} received. Starting graceful shutdown...`);

      server.close(async () => {
        console.log('🔌 HTTP + Socket.IO server closed');

        // Stop batch sync
        locationSync.stop();

        try {
          // await sequelize.close();
          // console.log('🔌 MySQL connection closed');
        } catch (err) {
          console.error('Error closing MySQL:', err.message);
        }

        try {
          await redis.quit();
          console.log('🔌 Redis connection closed');
        } catch (err) {
          console.error('Error closing Redis:', err.message);
        }

        console.log('✅ Graceful shutdown complete');
        process.exit(0);
      });

      // Force shutdown after 10 seconds
      setTimeout(() => {
        console.error('⚠️  Forced shutdown after timeout');
        process.exit(1);
      }, 10000);
    };

    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));

  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

startServer();

