const express = require('express');
const router = express.Router();
const { authenticateJWT } = require('../middleware/v1Auth');
const buyerProfileController = require('../controllers/buyerProfileController');
const buyerAddressController = require('../controllers/buyerAddressController');
const buyerFavoritesController = require('../controllers/buyerFavoritesController');
const buyerTrackingController = require('../controllers/buyerTrackingController');
const buyerNotificationsController = require('../controllers/buyerNotificationsController');

router.use(authenticateJWT);

router.get('/profile', buyerProfileController.getProfile);
router.put('/profile', buyerProfileController.updateProfile);
router.post('/avatar', buyerProfileController.uploadAvatar);
router.get('/preferences', buyerProfileController.getPreferences);
router.put('/preferences', buyerProfileController.updatePreferences);

router.get('/addresses', buyerAddressController.getAddresses);
router.post('/addresses', buyerAddressController.addAddress);
router.put('/addresses/:id', buyerAddressController.updateAddress);
router.delete('/addresses/:id', buyerAddressController.deleteAddress);

router.get('/favorites', buyerFavoritesController.getFavorites);
router.post('/favorites/:vendorId/toggle', buyerFavoritesController.toggleFavorite);

router.get('/daily-trackings', buyerTrackingController.getDailyTrackings);
router.put('/daily-trackings/:vendorId', buyerTrackingController.updateTrackingPreferences);
router.delete('/daily-trackings/:vendorId', buyerTrackingController.removeTracking);

router.get('/notifications', buyerNotificationsController.getNotifications);
router.put('/notifications/mark-read', buyerNotificationsController.markAsRead);

module.exports = router;
