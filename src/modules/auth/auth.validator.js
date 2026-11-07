const Joi = require('joi');

const sendOtp = {
  body: Joi.object({
    mobile: Joi.string()
      .pattern(/^[6-9]\d{9}$/)
      .required()
      .messages({
        'string.pattern.base': 'Please enter a valid 10-digit Indian mobile number',
        'any.required': 'Mobile number is required',
      }),
  }),
};

const verifyOtp = {
  body: Joi.object({
    mobile: Joi.string()
      .pattern(/^[6-9]\d{9}$/)
      .required()
      .messages({
        'string.pattern.base': 'Please enter a valid 10-digit Indian mobile number',
        'any.required': 'Mobile number is required',
      }),
    otp: Joi.string()
      .min(4)
      .max(6)
      .pattern(/^\d+$/)
      .required()
      .messages({
        'string.min': 'OTP must be at least 4 digits',
        'string.max': 'OTP must be at most 6 digits',
        'string.pattern.base': 'OTP must contain only numbers',
        'any.required': 'OTP is required',
      }),
  }),
};

module.exports = { sendOtp, verifyOtp };
