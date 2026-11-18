const ApiError = require('../utils/ApiError');

const errorHandler = (err, req, res, next) => {
  let statusCode = 500;
  let message = 'Internal Server Error';
  let errors = [];
  let code = 'INTERNAL_ERROR';

  if (err instanceof ApiError) {
    statusCode = err.statusCode;
    message = err.message;
    errors = err.errors;
    code = err.code;
  } else if (err.name === 'ValidationError') {
    statusCode = 400;
    message = err.message;
    code = 'VALIDATION_ERROR';
  } else if (err.code === 'P2002') {
    // Prisma unique constraint violation
    statusCode = 409;
    const target = err.meta?.target ? ` (${err.meta.target.join(', ')})` : '';
    message = `Unique constraint violated${target}`;
    code = 'DUPLICATE_ENTRY';
  } else if (err.code === 'P2025') {
    // Prisma record not found
    statusCode = 404;
    message = 'Requested record not found';
    code = 'NOT_FOUND';
  } else if (err.code === 'P2003') {
    // Prisma foreign key violation: the request referenced a missing record.
    statusCode = 400;
    message = 'A referenced record does not exist';
    code = 'INVALID_REFERENCE';
  } else {
    console.error('Unhandled Server Error:', err);
  }

  res.status(statusCode).json({
    success: false,
    message,
    code,
    errors: errors.length > 0 ? errors : undefined,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
  });
};

module.exports = errorHandler;

