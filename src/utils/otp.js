const redis = require('../config/redis');
const config = require('../config');

/**
 * OTP utility — generate, store, verify, and delete OTPs
 * Uses Redis when available, falls back to in-memory Map for development
 */

// In-memory fallback when Redis is unavailable
const memoryStore = new Map();

function isRedisReady() {
  return redis && redis.status === 'ready';
}

const otpUtil = {
  /**
   * Generate a 6-digit numeric OTP
   * @returns {string} 6-digit OTP string
   */
  generate() {
    return Math.floor(100000 + Math.random() * 900000).toString();
  },

  /**
   * Store OTP with TTL
   * @param {string} mobile - Mobile number (used as key)
   * @param {string} otp - The OTP to store
   */
  async store(mobile, otp) {
    const key = `otp:${mobile}`;
    if (isRedisReady()) {
      await redis.set(key, otp, 'EX', config.auth.otpExpirySeconds);
    } else {
      // In-memory fallback with auto-expiry
      memoryStore.set(key, otp);
      setTimeout(() => memoryStore.delete(key), config.auth.otpExpirySeconds * 1000);
    }
  },

  /**
   * Verify OTP against stored value
   * @param {string} mobile - Mobile number
   * @param {string} otp - OTP to verify
   * @returns {boolean} True if OTP matches
   */
  async verify(mobile, otp) {
    const key = `otp:${mobile}`;
    let storedOtp;

    if (isRedisReady()) {
      storedOtp = await redis.get(key);
    } else {
      storedOtp = memoryStore.get(key);
    }

    if (!storedOtp) {
      return false; // OTP expired or never sent
    }

    return storedOtp === otp;
  },

  /**
   * Delete OTP after successful verification
   * @param {string} mobile - Mobile number
   */
  async delete(mobile) {
    const key = `otp:${mobile}`;
    if (isRedisReady()) {
      await redis.del(key);
    } else {
      memoryStore.delete(key);
    }
  },
};

module.exports = otpUtil;
