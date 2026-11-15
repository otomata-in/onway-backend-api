const express = require('express');
const router = express.Router();
const tripsController = require('./trips.controller');
const { authenticate, optionalAuthenticate } = require('../../middleware/authenticate');

router.get('/hub', authenticate, tripsController.getTripsHub);
router.post('/plans', authenticate, tripsController.createTripPlan);
router.get('/plans/saved', authenticate, tripsController.getSavedTripPlans);
router.get('/plans/:id', optionalAuthenticate, tripsController.getTripPlanById);
router.post('/plans/:id/save', authenticate, tripsController.toggleSaveTripPlan);
router.post('/plans/:id/vote', authenticate, tripsController.voteTripPlan);
router.post('/plans/:id/start', authenticate, tripsController.startTripFromPlan);

router.get('/history', authenticate, tripsController.getTripHistory);

router.get('/:tripId', authenticate, tripsController.getTripById);
router.post('/:tripId/join', authenticate, tripsController.joinActiveTrip);
router.post('/:tripId/validate-waypoint', authenticate, tripsController.validateWaypoint);
router.post('/:tripId/complete', authenticate, tripsController.completeTrip);

module.exports = router;

