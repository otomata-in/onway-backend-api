const Joi = require('joi');

const register = {
  body: Joi.object({
    vehicle_name: Joi.string()
      .min(2)
      .max(100)
      .required()
      .messages({
        'any.required': 'Vehicle name is required',
        'string.min': 'Vehicle name must be at least 2 characters',
        'string.max': 'Vehicle name must not exceed 100 characters',
      }),
  }),
};

const toggleStatus = {
  body: Joi.object({
    is_active: Joi.boolean()
      .required()
      .messages({
        'any.required': 'is_active is required',
        'boolean.base': 'is_active must be a boolean',
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

module.exports = { register, toggleStatus, updateLocation };
