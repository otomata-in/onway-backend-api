const express = require('express');
const router = express.Router();
const notificationsController = require('./notifications.controller');
const { authenticate } = require('../../middleware/authenticate');

router.get('/', authenticate, notificationsController.getNotifications);
router.patch('/:id/read', authenticate, notificationsController.markRead);
router.patch('/read-all', authenticate, notificationsController.markAllRead);

module.exports = router;
