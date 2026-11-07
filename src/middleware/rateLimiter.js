const rateLimit = require('express-rate-limit');
const config = require('../config');

/**
 * OTP rate limiter — max 3 OTP requests per 5 minutes per IP
 * Prevents OTP abuse and SMS cost overruns
 */
const otpLimiter = rateLimit({
  windowMs: config.rateLimit.otpWindowMinutes * 60 * 1000,
  max: config.rateLimit.otpMaxAttempts,
  message: {
    error: true,
    message: 'Too many OTP requests. Please try again later.',
    code: 'OTP_RATE_LIMITED',
  },
  standardHeaders: true,   // Return rate limit info in RateLimit-* headers
  legacyHeaders: false,    // Disable X-RateLimit-* headers
  keyGenerator: (req) => {
    // Rate limit by mobile number if available, otherwise by IP
    return req.body?.mobile || 'ip-' + req.ip;
  },
  validate: { xForwardedForHeader: false, keyGeneratorIpFallback: false },
});

/**
 * General API rate limiter — 100 requests per 15 minutes per IP
 * Prevents abuse of all endpoints
 */
const generalLimiter = rateLimit({
  windowMs: config.rateLimit.generalWindowMinutes * 60 * 1000,
  max: config.rateLimit.generalMaxRequests,
  message: {
    error: true,
    message: 'Too many requests. Please try again later.',
    code: 'RATE_LIMITED',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

module.exports = { otpLimiter, generalLimiter };
