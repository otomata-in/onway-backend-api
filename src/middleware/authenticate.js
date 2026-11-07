const { AuthToken, User } = require('../models');
const ApiError = require('../utils/ApiError');

/**
 * Authentication middleware
 * Extracts Bearer token from Authorization header,
 * validates it against auth_tokens table,
 * and attaches user to req.user
 */
const authenticate = async (req, res, next) => {
  try {
    // Extract token from header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw ApiError.unauthorized('Missing or invalid authorization header');
    }

    const token = authHeader.split(' ')[1];

    if (!token) {
      throw ApiError.unauthorized('Token not provided');
    }

    // Look up token in database
    const authToken = await AuthToken.findOne({
      where: { token },
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'mobile', 'role', 'fcm_token'],
      }],
    });

    if (!authToken || !authToken.user) {
      throw ApiError.unauthorized('Invalid or expired token');
    }

    // Attach user to request
    req.user = authToken.user;
    req.token = token;

    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Role-based authorization middleware
 * Use after authenticate middleware
 * @param  {...string} roles - Allowed roles (e.g., 'seller', 'buyer')
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(ApiError.unauthorized('Authentication required'));
    }

    if (!roles.includes(req.user.role)) {
      return next(ApiError.forbidden(`Access denied. Required role: ${roles.join(' or ')}`));
    }

    next();
  };
};

module.exports = { authenticate, authorize };
