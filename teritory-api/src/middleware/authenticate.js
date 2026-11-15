const jwt = require('jsonwebtoken');
const prisma = require('../config/prisma');
const ApiError = require('../utils/ApiError');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw ApiError.unauthorized('Authentication token is required');
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      throw ApiError.unauthorized('Token missing from authorization header');
    }

    const secret = process.env.JWT_SECRET || 'teritory_secret';
    let decoded;
    try {
      decoded = jwt.verify(token, secret);
    } catch (err) {
      throw ApiError.unauthorized('Invalid or expired authentication token');
    }

    const user = await prisma.user.findUnique({
      where: { id: decoded.sub || decoded.id },
    });

    if (!user || !user.isActive) {
      throw ApiError.unauthorized('User account not found or suspended');
    }

    req.user = user;
    next();
  } catch (error) {
    next(error);
  }
};

const optionalAuthenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const secret = process.env.JWT_SECRET || 'teritory_secret';
      const decoded = jwt.verify(token, secret);
      const user = await prisma.user.findUnique({
        where: { id: decoded.sub || decoded.id },
      });
      if (user && user.isActive) {
        req.user = user;
      }
    }
  } catch (err) {
    // Silently continue for optional authentication
  }
  next();
};

module.exports = {
  authenticate,
  optionalAuthenticate,
};
