const express = require('express');
const router = express.Router();
const authController = require('./auth.controller');
const validate = require('../../middleware/validate');
const authValidator = require('./auth.validator');
const { otpLimiter } = require('../../middleware/rateLimiter');
const { authenticate } = require('../../middleware/authenticate');

// POST /auth/send-otp — Send OTP to mobile
router.post(
  '/send-otp',
  otpLimiter,
  validate(authValidator.sendOtp),
  authController.sendOtp
);

// POST /auth/verify-otp — Verify OTP and get token
router.post(
  '/verify-otp',
  validate(authValidator.verifyOtp),
  authController.verifyOtp
);

// POST /auth/logout — Invalidate token (requires auth)
router.post(
  '/logout',
  authenticate,
  authController.logout
);

module.exports = router;
