const express = require('express');
const router = express.Router();
const communitiesController = require('./communities.controller');
const { authenticate, optionalAuthenticate } = require('../../middleware/authenticate');

router.get('/', optionalAuthenticate, communitiesController.listCommunities);
router.post('/', authenticate, communitiesController.createCommunity);
router.get('/mine', authenticate, communitiesController.getMyCommunities);
router.get('/:id', optionalAuthenticate, communitiesController.getCommunityById);
router.post('/:id/join', authenticate, communitiesController.joinCommunity);
router.post('/:id/leave', authenticate, communitiesController.leaveCommunity);

router.get('/:id/feed', optionalAuthenticate, communitiesController.getCommunityFeed);
router.get('/:id/messages', authenticate, communitiesController.getCommunityMessages);
router.post('/:id/messages', authenticate, communitiesController.sendCommunityMessage);
router.get('/:id/members', optionalAuthenticate, communitiesController.getCommunityMembers);
router.get('/:id/trip-plans', optionalAuthenticate, communitiesController.getCommunityTripPlans);

module.exports = router;

