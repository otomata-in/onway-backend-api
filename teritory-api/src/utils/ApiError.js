class ApiError extends Error {
  constructor(statusCode, message, errors = [], code = null) {
    super(message);
    this.statusCode = statusCode;
    this.errors = errors;
    this.code = code;
    Error.captureStackTrace(this, this.constructor);
  }

  static badRequest(message, errors = [], code = 'BAD_REQUEST') {
    return new ApiError(400, message, errors, code);
  }

  static unauthorized(message = 'Unauthorized access', code = 'UNAUTHORIZED') {
    return new ApiError(401, message, [], code);
  }

  static forbidden(message = 'Access forbidden', code = 'FORBIDDEN') {
    return new ApiError(403, message, [], code);
  }

  static notFound(message = 'Resource not found', code = 'NOT_FOUND') {
    return new ApiError(404, message, [], code);
  }

  static conflict(message = 'Resource conflict', code = 'CONFLICT') {
    return new ApiError(409, message, [], code);
  }

  static internal(message = 'Internal server error', code = 'INTERNAL_ERROR') {
    return new ApiError(500, message, [], code);
  }
}

module.exports = ApiError;

