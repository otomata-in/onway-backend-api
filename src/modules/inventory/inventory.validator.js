const Joi = require('joi');

const addItem = {
  body: Joi.object({
    name: Joi.string()
      .min(1)
      .max(100)
      .required()
      .messages({
        'any.required': 'Item name is required',
        'string.max': 'Item name must not exceed 100 characters',
      }),
    price: Joi.number()
      .positive()
      .precision(2)
      .required()
      .messages({
        'any.required': 'Price is required',
        'number.positive': 'Price must be a positive number',
      }),
    quantity: Joi.number()
      .integer()
      .min(0)
      .default(0)
      .messages({
        'number.min': 'Quantity cannot be negative',
      }),
    is_available: Joi.boolean()
      .default(true),
  }),
};

const updateItem = {
  params: Joi.object({
    id: Joi.number()
      .integer()
      .positive()
      .required()
      .messages({
        'any.required': 'Item ID is required',
      }),
  }),
  body: Joi.object({
    name: Joi.string()
      .min(1)
      .max(100)
      .messages({
        'string.max': 'Item name must not exceed 100 characters',
      }),
    price: Joi.number()
      .positive()
      .precision(2)
      .messages({
        'number.positive': 'Price must be a positive number',
      }),
    quantity: Joi.number()
      .integer()
      .min(0)
      .messages({
        'number.min': 'Quantity cannot be negative',
      }),
    is_available: Joi.boolean(),
  }).min(1).messages({
    'object.min': 'At least one field must be provided for update',
  }),
};

const deleteItem = {
  params: Joi.object({
    id: Joi.number()
      .integer()
      .positive()
      .required(),
  }),
};

module.exports = { addItem, updateItem, deleteItem };
