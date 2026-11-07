const ApiError = require('../utils/ApiError');

/**
 * Joi validation middleware factory
 * Validates req.body, req.params, and req.query against provided schemas
 *
 * Usage:
 *   const { body, params } = require('./auth.validator');
 *   router.post('/endpoint', validate({ body: bodySchema }), controller.method);
 */
const validate = (schemas) => {
  return (req, res, next) => {
    const errors = [];

    // Validate each part of the request
    for (const [key, schema] of Object.entries(schemas)) {
      if (!schema) continue;

      const dataToValidate = req[key];
      const { error, value } = schema.validate(dataToValidate, {
        abortEarly: false,      // Report all errors, not just the first
        stripUnknown: true,     // Remove unknown fields
        allowUnknown: false,
      });

      if (error) {
        const details = error.details.map((detail) => ({
          field: detail.path.join('.'),
          message: detail.message.replace(/"/g, ''),
        }));
        errors.push(...details);
      } else {
        // Replace with validated (and sanitized) values
        req[key] = value;
      }
    }

    if (errors.length > 0) {
      const message = errors.map((e) => `${e.field}: ${e.message}`).join('; ');
      return next(ApiError.badRequest(message, 'VALIDATION_ERROR'));
    }

    next();
  };
};

module.exports = validate;
