const express = require('express');
const router = express.Router();
const { authenticateJWT } = require('../middleware/v1Auth');
const {
  getDashboardStats,
  toggleBroadcast,
  toggleDeliveryMode,
  updateLocation,
} = require('../controllers/vendorController');

router.use(authenticateJWT);

router.get('/dashboard-stats', getDashboardStats);
router.patch('/toggle-broadcast', toggleBroadcast);
router.patch('/toggle-delivery-mode', toggleDeliveryMode);
router.post('/update-location', updateLocation);

module.exports = router;
