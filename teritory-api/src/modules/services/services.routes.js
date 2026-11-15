const express = require('express');
const router = express.Router();
const servicesController = require('./services.controller');
const { optionalAuthenticate } = require('../../middleware/authenticate');

router.get('/gear', optionalAuthenticate, servicesController.getGearServices);
router.get('/nearby-food', optionalAuthenticate, servicesController.getNearbyFood);

module.exports = router;
