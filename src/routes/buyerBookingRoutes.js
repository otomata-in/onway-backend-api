const express = require('express');
const router = express.Router();
const { authenticateJWT } = require('../middleware/v1Auth');
const buyerBookingsController = require('../controllers/buyerBookingsController');

router.use(authenticateJWT);

router.post('/', buyerBookingsController.createBooking);
router.get('/active', buyerBookingsController.getActiveBookings);
router.get('/history', buyerBookingsController.getBookingHistory);
router.get('/:id', buyerBookingsController.getBookingDetails);
router.get('/:id/tracking', buyerBookingsController.getBookingTracking);
router.post('/:id/reorder', buyerBookingsController.reorderBooking);

module.exports = router;
