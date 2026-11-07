const express = require('express');
const router = express.Router();
const { sendOtp, verifyOtp, getSession, logout } = require('../controllers/authController');
const { authenticateJWT } = require('../middleware/v1Auth');

router.post('/send-otp', sendOtp);
router.post('/verify-otp', verifyOtp);
router.get('/session', authenticateJWT, getSession);
router.post('/logout', authenticateJWT, logout);

module.exports = router;
