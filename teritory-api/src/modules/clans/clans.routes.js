const express = require('express');
const router = express.Router();
const clansController = require('./clans.controller');
const { authenticate, optionalAuthenticate } = require('../../middleware/authenticate');

router.get('/', optionalAuthenticate, clansController.getClans);
router.get('/my', authenticate, clansController.getMyClans);
router.post('/', authenticate, clansController.createClan);

router.get('/:clanId', optionalAuthenticate, clansController.getClanById);
router.post('/:clanId/join', authenticate, clansController.joinClan);
router.post('/:clanId/leave', authenticate, clansController.leaveClan);
router.get('/:clanId/communities', optionalAuthenticate, clansController.getClanCommunities);

module.exports = router;

