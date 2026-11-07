const express = require('express');
const router = express.Router();
const inventoryController = require('./inventory.controller');
const validate = require('../../middleware/validate');
const inventoryValidator = require('./inventory.validator');
const { authenticate, authorize } = require('../../middleware/authenticate');

// All inventory routes require seller role
router.use(authenticate, authorize('seller'));

// GET /seller/items — Get all seller's items
router.get(
  '/',
  inventoryController.getItems
);

// POST /seller/items — Add new item
router.post(
  '/',
  validate(inventoryValidator.addItem),
  inventoryController.addItem
);

// PUT /seller/items/:id — Update item
router.put(
  '/:id',
  validate(inventoryValidator.updateItem),
  inventoryController.updateItem
);

// DELETE /seller/items/:id — Soft delete item
router.delete(
  '/:id',
  validate(inventoryValidator.deleteItem),
  inventoryController.deleteItem
);

module.exports = router;
