const express = require('express');
const router = express.Router();
const authController = require('./auth.controller');
const authValidator = require('./auth.validator');
const validate = require('../../middleware/validate');
const { authenticate } = require('../../middleware/authenticate');

router.post('/send-otp', validate(authValidator.sendOtp), authController.sendOtp);
router.post('/verify-otp', validate(authValidator.verifyOtp), authController.verifyOtp);
router.post('/refresh', authController.refreshToken);
router.post('/logout', authenticate, authController.logout);
router.get('/me', authenticate, authController.getMe);

module.exports = router;

