const express = require('express');
const router = express.Router();
const flagsController = require('./flags.controller');
const { authenticate, optionalAuthenticate } = require('../../middleware/authenticate');

router.get('/', optionalAuthenticate, flagsController.exploreFlags);
router.get('/explore', optionalAuthenticate, flagsController.exploreFlags);
router.get('/sub-territories', optionalAuthenticate, flagsController.getSubTerritories);
router.get('/wonders', optionalAuthenticate, flagsController.getWonders);
router.get('/search', optionalAuthenticate, flagsController.searchFlags);
router.get('/saved', authenticate, flagsController.getSavedFlags);
router.post('/', authenticate, flagsController.dropFlag);

router.get('/:id', optionalAuthenticate, flagsController.getFlagById);
router.delete('/:id', authenticate, flagsController.deleteFlag);
router.post('/:id/save', authenticate, flagsController.toggleSaveFlag);
router.post('/:id/reactions', authenticate, flagsController.toggleReaction);
router.post('/:id/comments', authenticate, flagsController.addComment);
router.post('/:id/kudos', authenticate, flagsController.addKudos);

module.exports = router;

