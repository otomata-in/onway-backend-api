const express = require('express');
const router = express.Router();
const { authenticate } = require('../../middleware/authenticate');
const { upload, uploadImage } = require('./upload.controller');

router.post('/', authenticate, upload.single('image'), uploadImage);

module.exports = router;
