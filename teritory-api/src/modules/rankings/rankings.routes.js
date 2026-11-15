const express = require('express');
const router = express.Router();
const rankingsController = require('./rankings.controller');
const { authenticate, optionalAuthenticate } = require('../../middleware/authenticate');

router.get('/', optionalAuthenticate, rankingsController.getLeaderboard);
router.get('/me', authenticate, rankingsController.getMyRank);

module.exports = router;
