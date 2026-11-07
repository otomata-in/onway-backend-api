const express = require('express');
const router = express.Router();
const userController = require('./user.controller');
const validate = require('../../middleware/validate');
const userValidator = require('./user.validator');
const { authenticate } = require('../../middleware/authenticate');

// All user routes require authentication
router.use(authenticate);

// GET /me — Get current user profile
router.get(
  '/',
  userController.getMe
);

// POST /users/fcm-token — Save FCM token
router.post(
  '/fcm-token',
  validate(userValidator.saveFcmToken),
  userController.saveFcmToken
);

// PUT /me/location — Update user location
router.put(
  '/location',
  validate(userValidator.updateLocation),
  userController.updateLocation
);

module.exports = router;
