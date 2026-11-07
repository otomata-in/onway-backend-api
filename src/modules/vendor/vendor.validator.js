const Joi = require('joi');

const nearby = {
  query: Joi.object({
    lat: Joi.number()
      .min(-90)
      .max(90)
      .required()
      .messages({
        'any.required': 'Latitude is required',
      }),
    lng: Joi.number()
      .min(-180)
      .max(180)
      .required()
      .messages({
        'any.required': 'Longitude is required',
      }),
    radius: Joi.number()
      .positive()
      .max(50)       // Max 50 km radius
      .default(5)    // Default 5 km
      .messages({
        'number.positive': 'Radius must be positive',
        'number.max': 'Radius cannot exceed 50 km',
      }),
  }),
};

const vendorId = {
  params: Joi.object({
    id: Joi.number()
      .integer()
      .positive()
      .required()
      .messages({
        'any.required': 'Vendor ID is required',
      }),
  }),
};

const vendorETA = {
  params: Joi.object({
    id: Joi.number().integer().positive().required(),
  }),
  query: Joi.object({
    lat: Joi.number()
      .min(-90)
      .max(90)
      .required()
      .messages({ 'any.required': 'Latitude is required' }),
    lng: Joi.number()
      .min(-180)
      .max(180)
      .required()
      .messages({ 'any.required': 'Longitude is required' }),
  }),
};

module.exports = { nearby, vendorId, vendorETA };
