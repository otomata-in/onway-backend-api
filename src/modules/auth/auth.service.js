const { v4: uuidv4 } = require('uuid');
const { User, AuthToken } = require('../../models');
const smsService = require('../../utils/sms');
const ApiError = require('../../utils/ApiError');

const authService = {
  /**
   * Send OTP to mobile number
   * Uses Twilio Verify API
   */
  async sendOtp(mobile) {
    // Send OTP via SMS (Twilio)
    await smsService.sendOTP(mobile);

    return { message: 'OTP sent successfully' };
  },

  /**
   * Verify OTP and authenticate user
   * 1. Validate OTP using Twilio Verify
   * 2. Upsert user (find or create)
   * 3. Generate auth token
   * 4. Store token in DB
   * 5. Return token + user data
   */
  async verifyOtp(mobile, otp) {
    // Verify OTP via Twilio
    const isValid = await smsService.verifyOTP(mobile, otp);

    if (!isValid) {
      throw ApiError.badRequest('Invalid or expired OTP', 'INVALID_OTP');
    }

    // Find or create user
    const [user, created] = await User.findOrCreate({
      where: { mobile },
      defaults: { mobile, role: 'buyer' },
    });

    if (created) {
      console.log(`🆕 New user registered: ${mobile}`);
    }

    // Generate auth token
    const token = uuidv4();

    // Store token in database
    await AuthToken.create({
      user_id: user.id,
      token,
    });

    return {
      token,
      user: {
        id: user.id,
        mobile: user.mobile,
        role: user.role,
      },
    };
  },

  /**
   * Logout — delete the auth token
   */
  async logout(token) {
    const deleted = await AuthToken.destroy({ where: { token } });

    if (!deleted) {
      throw ApiError.badRequest('Token not found', 'TOKEN_NOT_FOUND');
    }

    return { message: 'Logged out successfully' };
  },
};

module.exports = authService;
