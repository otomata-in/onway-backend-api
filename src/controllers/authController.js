const jwt = require('jsonwebtoken');
const prisma = require('../config/prisma');
const { generateOtpCode, sendSmsOtp, checkSmsOtp } = require('../services/twilioService');

const JWT_SECRET = process.env.JWT_SECRET || 'onway_market_secret_jwt_key_2026';
const ENABLE_TWILIO_SMS = process.env.ENABLE_TWILIO_SMS === 'true'; // Set to true in prod to trigger live SMS

/**
  POST /api/v1/auth/send-otp
  Sends 5-digit verification OTP code. In development/bypass mode, uses 12345 to save Twilio costs.
 */
async function sendOtp(req, res) {
  try {
    const phone = req.body.phone || req.body.mobile;
    const role = req.body.role || 'BUYER';
    if (!phone) {
      return res.status(400).json({ success: false, error: 'Mobile phone number is required' });
    }

    const otpCode = '12345'; // Development bypass OTP to save Twilio SMS credits
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 mins expiry

    // Save to TwilioOtpLog
    await prisma.twilioOtpLog.create({
      data: {
        phone,
        otpCode,
        expiresAt,
      },
    });

    let twilioResult = { bypassed: true, devOtp: '12345' };

    // Send real SMS via Twilio Gateway ONLY if explicitly enabled
    if (ENABLE_TWILIO_SMS) {
      twilioResult = await sendSmsOtp(phone, otpCode);
    } else {
      console.log(`[Twilio Cost Saver] SMS Bypassed for ${phone}. Use Dev OTP: 12345`);
    }

    return res.status(200).json({
      success: true,
      message: 'Verification OTP sent successfully. (Development mode: Use OTP 12345)',
      phone,
      devOtp: '12345',
      twilioResult,
    });
  } catch (err) {
    console.error('Error in sendOtp:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}

/**
  POST /api/v1/auth/verify-otp
  Validates OTP code, logs user in, returns signed JWT
 */
async function verifyOtp(req, res) {
  try {
    const { phone, otpCode, mobile, otp, role = 'BUYER', fullName, businessName, vehicleNumber } = req.body;
    const targetPhone = phone || mobile;
    const targetOtp = otpCode || otp;

    if (!targetPhone || !targetOtp) {
      return res.status(400).json({ success: false, error: 'Phone and OTP code are required' });
    }

    // Dev bypass check for '12345' or '123456'
    let isValid = targetOtp === '12345' || targetOtp === '123456' || targetOtp === '123450';

    
    if (!isValid && ENABLE_TWILIO_SMS) {
      // 1. Try Twilio Verify API if enabled
      const twilioCheck = await checkSmsOtp(phone, otpCode);
      if (twilioCheck.success) {
        isValid = true;
      }
    }

    if (!isValid) {
      // 2. Local DB log check
      const otpLog = await prisma.twilioOtpLog.findFirst({
        where: {
          phone: targetPhone,
          otpCode: targetOtp,
          isUsed: false,
          expiresAt: { gte: new Date() },
        },
        orderBy: { createdAt: 'desc' },
      });

      if (otpLog) {
        isValid = true;
        await prisma.twilioOtpLog.update({
          where: { id: otpLog.id },
          data: { isUsed: true },
        });
      }
    }

    if (!isValid) {
      return res.status(400).json({ success: false, error: 'Invalid OTP. For development testing, use code: 12345' });
    }

    // Find or create User
    let user = await prisma.user.findUnique({
      where: { phone: targetPhone },
      include: { buyerProfile: true, vendorProfile: true },
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          phone,
          role: role.toUpperCase(),
          isVerified: true,
        },
      });

      if (role.toUpperCase() === 'VENDOR') {
        await prisma.vendorProfile.create({
          data: {
            userId: user.id,
            businessName: businessName || 'Malabar Organic Produce',
            vehicleNumber: vehicleNumber || `KL-07-CD-${Math.floor(1000 + Math.random() * 9000)}`,
          },
        });
      } else {
        await prisma.buyerProfile.create({
          data: {
            userId: user.id,
            fullName: fullName || 'Buyer Account',
          },
        });
      }

      user = await prisma.user.findUnique({
        where: { id: user.id },
        include: { buyerProfile: true, vendorProfile: true },
      });
    }

    // Generate JWT Token
    const token = jwt.sign(
      {
        userId: user.id,
        phone: user.phone,
        role: user.role,
        profileId: user.role === 'VENDOR' ? user.vendorProfile?.id : user.buyerProfile?.id,
      },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    return res.status(200).json({
      success: true,
      message: 'Authentication successful',
      token,
      user,
    });
  } catch (err) {
    console.error('Error in verifyOtp:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}

async function getSession(req, res) {
  try {
    if (!req.user || !req.user.userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const user = await prisma.user.findUnique({
      where: { id: req.user.userId },
      include: { buyerProfile: true, vendorProfile: true },
    });

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    return res.status(200).json({ success: true, user });
  } catch (err) {
    console.error('Error in getSession:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}

async function logout(req, res) {
  return res.status(200).json({ success: true, message: 'Logged out successfully' });
}

module.exports = {
  sendOtp,
  verifyOtp,
  getSession,
  logout,
};
