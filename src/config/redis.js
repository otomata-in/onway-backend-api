const Redis = require('ioredis');
const config = require('./index');

let redis;

try {
  const redisOptions = {
    maxRetriesPerRequest: null,   // Don't throw MaxRetriesPerRequestError
    enableOfflineQueue: false,    // Reject commands immediately when disconnected
    retryStrategy(times) {
      if (times > 5) return null; // Stop retrying after 5 attempts
      const delay = Math.min(times * 500, 5000);
      return delay;
    },
    lazyConnect: true,  // Don't connect until first command or explicit connect()
  };

  if (process.env.REDIS_URL) {
    redis = new Redis(process.env.REDIS_URL, redisOptions);
  } else {
    redis = new Redis({
      ...redisOptions,
      host: config.redis.host,
      port: config.redis.port,
      password: config.redis.password,
    });
  }

  redis.on('connect', () => {
    console.log('✅ Redis connected');
  });

  let errorLogged = false;
  redis.on('error', (err) => {
    if (!errorLogged) {
      console.error('❌ Redis error:', err.message);
      errorLogged = true;
    }
  });

  let closeLogged = false;
  redis.on('close', () => {
    if (!closeLogged) {
      console.log('⚠️  Redis connection closed');
      closeLogged = true;
    }
  });
} catch (err) {
  console.error('❌ Failed to create Redis client:', err.message);
  process.exit(1);
}

module.exports = redis;
