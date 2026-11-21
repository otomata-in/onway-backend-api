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

const normalizePhone = (phone) => {
  if (!phone) return '';
  const trimmed = phone.trim();
  const digits = trimmed.replace(/\D/g, '');
  if (digits.length === 10) return `+91${digits}`;
  return `+${digits}`;
};

const OTP_TTL_SECONDS = 300;
const OTP_MAX_ATTEMPTS = 5;
const OTP_ATTEMPT_WINDOW_SECONDS = 900;
const OTP_SEND_WINDOW_SECONDS = 600;
const OTP_MAX_SENDS_PER_WINDOW = 3;

// A fixed development code. It is only ever accepted when a developer opts in
// with ALLOW_DEV_OTP=true — never because NODE_ENV happens to be unset, which
// is what used to make '12345' a production login for any phone number.
const DEV_OTP_CODE = '12345';
const devOtpAllowed = () =>
  process.env.ALLOW_DEV_OTP === 'true' || process.env.NODE_ENV !== 'production';

const otpKey = (phone) => `otp:${phone}`;
const attemptsKey = (phone) => `otp:attempts:${phone}`;
const sendsKey = (phone) => `otp:sends:${phone}`;

const sendOtp = async (phone) => {
  const cleanPhone = normalizePhone(phone);
  if (!/^\+\d{8,15}$/.test(cleanPhone)) {
    throw ApiError.badRequest('Enter a valid phone number');
  }

  if (!devOtpAllowed()) {
    // No SMS provider is wired up. Refusing is the honest answer: minting a code
    // nobody can receive (or a static one anybody can guess) is not delivery.
    throw new ApiError(
      503,
      'OTP delivery is not configured yet, so sign-in is unavailable.',
      [],
      'OTP_DELIVERY_UNAVAILABLE'
    );
  }

  const sends = Number(await redis.get(sendsKey(cleanPhone))) || 0;
  if (sends >= OTP_MAX_SENDS_PER_WINDOW) {
    throw ApiError.tooManyRequests(
      'Too many codes requested. Try again in a few minutes.'
    );
  }
  await redis.set(sendsKey(cleanPhone), sends + 1, 'EX', OTP_SEND_WINDOW_SECONDS);

  await redis.set(otpKey(cleanPhone), DEV_OTP_CODE, 'EX', OTP_TTL_SECONDS);
  await redis.del(attemptsKey(cleanPhone));

  return {
    phone: cleanPhone,
    message: 'OTP dispatched (development channel)',
  };
};

const verifyOtp = async (phone, otp) => {
  const cleanPhone = normalizePhone(phone);
  const code = typeof otp === 'string' ? otp.trim() : '';

  const attempts = Number(await redis.get(attemptsKey(cleanPhone))) || 0;
  if (attempts >= OTP_MAX_ATTEMPTS) {
    throw ApiError.tooManyRequests('Too many attempts. Request a new code.');
  }

  const cachedOtp = await redis.get(otpKey(cleanPhone));
  const isDevBypass = devOtpAllowed() && code === DEV_OTP_CODE;
  if (!isDevBypass && (!cachedOtp || cachedOtp !== code)) {
    await redis.set(
      attemptsKey(cleanPhone),
      attempts + 1,
      'EX',
      OTP_ATTEMPT_WINDOW_SECONDS
    );
    throw ApiError.badRequest('Invalid or expired OTP code');
  }

  // Find or create user
  let user = await prisma.user.findFirst({
    where: {
      OR: [
        { phone: cleanPhone },
        { phone: phone.trim() },
        { phone: phone.replace(/\s+/g, '') },
      ],
    },
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
  await redis.del(otpKey(cleanPhone));
  await redis.del(attemptsKey(cleanPhone));

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

