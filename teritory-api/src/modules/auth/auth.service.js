const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const prisma = require('../../config/prisma');
const redis = require('../../config/redis');
const ApiError = require('../../utils/ApiError');

const generateTokens = async (userId, handle) => {
  const accessToken = jwt.sign(
    { sub: userId, id: userId, handle },
    process.env.JWT_SECRET || 'teritory_secret',
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );

  const rawRefreshToken = crypto.randomBytes(40).toString('hex');
  const tokenHash = crypto.createHash('sha256').update(rawRefreshToken).digest('hex');

  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

  await prisma.refreshToken.create({
    data: {
      userId,
      tokenHash,
      expiresAt,
    },
  });

  return { accessToken, refreshToken: rawRefreshToken };
};

const sendOtp = async (phone) => {
  const cleanPhone = phone.trim();
  const testOtp = '12345'; // Development bypass OTP to cut SMS provider costs

  // Cache in redis/memory for 5 minutes
  await redis.set(`otp:${cleanPhone}`, testOtp, 'EX', 300);

  return {
    phone: cleanPhone,
    message: 'OTP dispatched successfully (Dev bypass: 12345)',
  };
};

const verifyOtp = async (phone, otp) => {
  const cleanPhone = phone.trim();
  const cachedOtp = await redis.get(`otp:${cleanPhone}`);

  // Allow '12345' (or legacy 123456) as static dev bypass in non-production, or match cached OTP
  const isDevBypass =
    process.env.NODE_ENV !== 'production' && (otp === '12345' || otp === '123456');
  if (!isDevBypass && cachedOtp !== otp) {
    throw ApiError.badRequest('Invalid or expired OTP code');
  }

  // Find or create user
  let user = await prisma.user.findFirst({
    where: { phone: cleanPhone },
  });

  let isNewUser = false;

  if (!user) {
    isNewUser = true;
    const autoHandle = `user_${cleanPhone.slice(-4)}_${Date.now().toString().slice(-4)}`;
    user = await prisma.user.create({
      data: {
        phone: cleanPhone,
        displayName: `Explorer ${cleanPhone.slice(-4)}`,
        handle: autoHandle,
        isVerified: true,
      },
    });
  }

  const tokens = await generateTokens(user.id, user.handle);
  await redis.del(`otp:${cleanPhone}`);

  return {
    user,
    isNewUser,
    ...tokens,
  };
};

const refreshToken = async (rawRefreshToken) => {
  if (!rawRefreshToken) {
    throw ApiError.unauthorized('Refresh token is required');
  }

  const tokenHash = crypto.createHash('sha256').update(rawRefreshToken).digest('hex');

  const storedToken = await prisma.refreshToken.findUnique({
    where: { tokenHash },
    include: { user: true },
  });

  if (!storedToken || storedToken.isRevoked || storedToken.expiresAt < new Date()) {
    throw ApiError.unauthorized('Invalid or expired refresh token');
  }

  // Revoke old refresh token
  await prisma.refreshToken.update({
    where: { id: storedToken.id },
    data: { isRevoked: true },
  });

  // Generate fresh token pair
  return await generateTokens(storedToken.user.id, storedToken.user.handle);
};

const logout = async (userId, rawRefreshToken) => {
  if (rawRefreshToken) {
    const tokenHash = crypto.createHash('sha256').update(rawRefreshToken).digest('hex');
    await prisma.refreshToken.updateMany({
      where: { userId, tokenHash },
      data: { isRevoked: true },
    });
  }
  return true;
};

module.exports = {
  sendOtp,
  verifyOtp,
  refreshToken,
  logout,
  generateTokens,
};

