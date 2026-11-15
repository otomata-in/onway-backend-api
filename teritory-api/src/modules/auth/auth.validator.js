const Joi = require('joi');

const sendOtp = {
  body: Joi.object().keys({
    phone: Joi.string().required(),
  }),
};

const verifyOtp = {
  body: Joi.object().keys({
    phone: Joi.string().required(),
    otp: Joi.string().required(),
  }),
};

const registerProfile = {
  body: Joi.object().keys({
    displayName: Joi.string().required().min(2).max(50),
    handle: Joi.string().required().min(3).max(30).alphanum(),
    bio: Joi.string().allow('', null).max(250),
    avatarUrl: Joi.string().uri().allow('', null),
    country: Joi.string().default('India'),
    state: Joi.string().allow('', null),
    district: Joi.string().allow('', null),
  }),
};

module.exports = {
  sendOtp,
  verifyOtp,
  registerProfile,
};
