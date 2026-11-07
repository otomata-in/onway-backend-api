const Joi = require('joi');

const saveFcmToken = {
  body: Joi.object({
    token: Joi.string()
      .min(1)
      .max(500)
      .required()
      .messages({
        'any.required': 'FCM token is required',
        'string.empty': 'FCM token cannot be empty',
      }),
  }),
};

const updateLocation = {
  body: Joi.object({
    lat: Joi.number()
      .min(-90)
      .max(90)
      .required()
      .messages({
        'any.required': 'Latitude is required',
        'number.min': 'Latitude must be between -90 and 90',
        'number.max': 'Latitude must be between -90 and 90',
      }),
    lng: Joi.number()
      .min(-180)
      .max(180)
      .required()
      .messages({
        'any.required': 'Longitude is required',
        'number.min': 'Longitude must be between -180 and 180',
        'number.max': 'Longitude must be between -180 and 180',
      }),
  }),
};

module.exports = { saveFcmToken, updateLocation };
