require('dotenv').config();

const config = {
  // Server
  port: parseInt(process.env.PORT, 10) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',

  // Database
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    name: process.env.DB_NAME || 'onway',
    dialect: 'mysql',
  },

  // Redis
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT, 10) || 6379,
    password: process.env.REDIS_PASSWORD || undefined,
  },

  // Auth
  auth: {
    tokenSecret: process.env.AUTH_TOKEN_SECRET || 'onway-dev-secret-change-me',
    otpExpirySeconds: parseInt(process.env.OTP_EXPIRY_SECONDS, 10) || 300,
  },

  // Rate limiting (relaxed in development for testing)
  rateLimit: {
    otpMaxAttempts: process.env.NODE_ENV === 'production' ? 3 : 50,
    otpWindowMinutes: 5,
    generalMaxRequests: process.env.NODE_ENV === 'production' ? 100 : 1000,
    generalWindowMinutes: 1,
  },

  // Firebase (FCM)
  firebase: {
    serviceAccountPath: process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './firebase-service-account.json',
  },
};

module.exports = config;
