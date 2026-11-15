const express = require('express');
const router = express.Router();
const usersController = require('./users.controller');
const { authenticate } = require('../../middleware/authenticate');

router.get('/me', authenticate, usersController.getMyProfile);
router.patch('/me', authenticate, usersController.updateMyProfile);
router.patch('/me/trip-mode', authenticate, usersController.toggleTripMode);

// Social & Friends
router.get('/friends', authenticate, usersController.getFriends);
router.post('/friends/request', authenticate, usersController.sendFriendRequest);
router.post('/friends/requests/:id/respond', authenticate, usersController.respondFriendRequest);

// Search & Invites
router.get('/search', authenticate, usersController.searchUsers);
router.post('/invites', authenticate, usersController.inviteFriends);

// Public user profile
router.get('/:userId', authenticate, usersController.getUserProfile);

module.exports = router;

