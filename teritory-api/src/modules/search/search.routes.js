const express = require('express');
const router = express.Router();
const searchController = require('./search.controller');
const { optionalAuthenticate } = require('../../middleware/authenticate');

router.get('/', optionalAuthenticate, searchController.omniSearch);

module.exports = router;
