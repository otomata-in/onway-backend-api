const express = require('express');
const router = express.Router();
const ralliesController = require('./rallies.controller');
const { authenticate, optionalAuthenticate } = require('../../middleware/authenticate');

router.get('/', optionalAuthenticate, ralliesController.getNearbyRallies);
router.get('/nearby', optionalAuthenticate, ralliesController.getNearbyRallies);
router.post('/', authenticate, ralliesController.createRally);

router.get('/:id', optionalAuthenticate, ralliesController.getRallyById);
router.post('/:id/join', authenticate, ralliesController.joinRally);
router.post('/:id/arrive', authenticate, ralliesController.markArrival);
router.post('/:id/complete', authenticate, ralliesController.completeRally);

module.exports = router;

