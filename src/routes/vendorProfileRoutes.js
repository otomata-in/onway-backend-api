const express = require('express');
const router = express.Router();
const { authenticateJWT } = require('../middleware/v1Auth');

const vendorProfileController = require('../controllers/vendorProfileController');
const vendorInventoryController = require('../controllers/vendorInventoryController');
const vendorRoutesController = require('../controllers/vendorRoutesController');

router.use(authenticateJWT);

router.get('/profile', vendorProfileController.getProfile);
router.put('/profile', vendorProfileController.updateProfile);
router.patch('/profile/operating-hours', vendorProfileController.updateOperatingHours);
router.post('/profile/vehicle-image', vendorProfileController.uploadVehicleImage);
router.get('/qr-data', vendorProfileController.getQrData);

router.get('/inventory', vendorInventoryController.getInventory);
router.post('/inventory', vendorInventoryController.addProduct);
router.patch('/inventory/:id', vendorInventoryController.updateProduct);
router.delete('/inventory/:id', vendorInventoryController.deleteProduct);

router.get('/routes', vendorRoutesController.getRoutes);
router.get('/routes/active', vendorRoutesController.getActiveRoute);
router.post('/routes', vendorRoutesController.createRoute);
router.put('/routes/:id', vendorRoutesController.updateRoute);
router.delete('/routes/:id', vendorRoutesController.deleteRoute);
router.patch('/routes/:id/activate', vendorRoutesController.activateRoute);

module.exports = router;
