const ApiError = require('../utils/ApiError');
const config = require('../config');

/**
 * Global error handler middleware
 * Must be registered LAST in the middleware chain
 */
const errorHandler = (err, req, res, next) => {
  // Default values
  let statusCode = err.statusCode || 500;
  let message = err.message || 'Internal server error';
  let code = err.code || 'INTERNAL_ERROR';

  // Handle Sequelize validation errors
  if (err.name === 'SequelizeValidationError') {
    statusCode = 400;
    code = 'VALIDATION_ERROR';
    message = err.errors.map((e) => e.message).join(', ');
  }

  // Handle Sequelize unique constraint errors
  if (err.name === 'SequelizeUniqueConstraintError') {
    statusCode = 409;
    code = 'DUPLICATE_ENTRY';
    message = 'A record with this value already exists';
  }

  // Handle Sequelize foreign key constraint errors
  if (err.name === 'SequelizeForeignKeyConstraintError') {
    statusCode = 400;
    code = 'INVALID_REFERENCE';
    message = 'Referenced record does not exist';
  }

  // Log error in development
  if (config.nodeEnv === 'development') {
    console.error('─── Error ───');
    console.error(`Status: ${statusCode}`);
    console.error(`Code: ${code}`);
    console.error(`Message: ${message}`);
    if (statusCode === 500) {
      console.error('Stack:', err.stack);
    }
    console.error('─────────────');
  }

  // Don't leak internal error details in production
  if (config.nodeEnv === 'production' && statusCode === 500 && !err.isOperational) {
    message = 'Something went wrong';
    code = 'INTERNAL_ERROR';
  }

  res.status(statusCode).json({
    error: true,
    message,
    code,
  });
};

module.exports = errorHandler;
