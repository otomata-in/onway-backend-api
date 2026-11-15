const Joi = require('joi');
const ApiError = require('../utils/ApiError');

const validate = (schema) => (req, res, next) => {
  const validSchema = Joi.object(schema);
  const objectToValidate = {};

  if (schema.params) objectToValidate.params = req.params;
  if (schema.query) objectToValidate.query = req.query;
  if (schema.body) objectToValidate.body = req.body;

  const { error, value } = validSchema.validate(objectToValidate, {
    abortEarly: false,
    allowUnknown: true,
    stripUnknown: true,
  });

  if (error) {
    const errorDetails = error.details.map((detail) => ({
      field: detail.path.join('.').replace(/^(params|query|body)\./, ''),
      message: detail.message.replace(/['"]/g, ''),
    }));
    return next(ApiError.badRequest('Validation error', errorDetails));
  }

  if (value.params) req.params = value.params;
  if (value.query) req.query = value.query;
  if (value.body) req.body = value.body;

  next();
};

module.exports = validate;
