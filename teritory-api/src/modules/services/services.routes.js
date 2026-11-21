const express = require('express');
const router = express.Router();
const servicesController = require('./services.controller');
const { optionalAuthenticate, authenticate } = require('../../middleware/authenticate');

router.get('/gear', optionalAuthenticate, servicesController.getGearServices);
router.get('/nearby-food', optionalAuthenticate, servicesController.getNearbyFood);
router.post('/:id/inquiry', authenticate, servicesController.recordInquiry);

module.exports = router;

