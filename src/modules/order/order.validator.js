const Joi = require('joi');

const createOrder = {
  body: Joi.object({
    vendor_id: Joi.number()
      .integer()
      .positive()
      .required()
      .messages({
        'any.required': 'Vendor ID is required',
      }),
    buyer_lat: Joi.number()
      .min(-90)
      .max(90)
      .required()
      .messages({
        'any.required': 'Buyer latitude is required',
      }),
    buyer_lng: Joi.number()
      .min(-180)
      .max(180)
      .required()
      .messages({
        'any.required': 'Buyer longitude is required',
      }),
    items: Joi.array()
      .items(
        Joi.object({
          item_id: Joi.number().integer().positive().required(),
          qty: Joi.number().integer().min(1).required(),
        })
      )
      .min(1)
      .required()
      .messages({
        'any.required': 'At least one item is required',
        'array.min': 'At least one item is required',
      }),
  }),
};

const getOrders = {
  query: Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(50).default(20),
    status: Joi.string()
      .valid('requested', 'accepted', 'rejected', 'fulfilled', 'expired')
      .optional(),
  }),
};

const orderId = {
  params: Joi.object({
    id: Joi.number()
      .integer()
      .positive()
      .required()
      .messages({
        'any.required': 'Order ID is required',
      }),
  }),
};

module.exports = { createOrder, getOrders, orderId };
