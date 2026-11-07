const express = require('express');
const router = express.Router();
const { authenticateJWT } = require('../middleware/v1Auth');
const {
  getTodaysEnquiries,
  getOrderHistory,
  updateOrderStatus,
  ringBuyer,
  createOrder,
} = require('../controllers/orderController');

router.use(authenticateJWT);

router.get('/todays', getTodaysEnquiries);
router.get('/history', getOrderHistory);
router.patch('/:id/status', updateOrderStatus);
router.post('/:id/ring-buyer', ringBuyer);
router.post('/create', createOrder);

module.exports = router;
