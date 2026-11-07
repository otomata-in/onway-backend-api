const Joi = require('joi');

const pointSchema = Joi.object({
  lat: Joi.number().min(-90).max(90).required(),
  lng: Joi.number().min(-180).max(180).required(),
  sequence: Joi.number().integer().min(0).required(),
});

const createRoute = {
  body: Joi.object({
    name: Joi.string()
      .min(2)
      .max(100)
      .required()
      .messages({
        'any.required': 'Route name is required',
        'string.min': 'Route name must be at least 2 characters',
      }),
    points: Joi.array()
      .items(pointSchema)
      .min(2)
      .required()
      .messages({
        'any.required': 'Route points are required',
        'array.min': 'Route must have at least 2 points (start and end)',
      }),
  }),
};

const updateRoute = {
  params: Joi.object({
    id: Joi.number().integer().positive().required(),
  }),
  body: Joi.object({
    name: Joi.string().min(2).max(100),
    points: Joi.array().items(pointSchema).min(2),
  }).min(1).messages({
    'object.min': 'At least one field must be provided for update',
  }),
};

const routeId = {
  params: Joi.object({
    id: Joi.number().integer().positive().required(),
  }),
};

module.exports = { createRoute, updateRoute, routeId };
