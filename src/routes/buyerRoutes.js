const express = require('express');
const router = express.Router();
const { authenticateJWT } = require('../middleware/v1Auth');
const buyerVendorsController = require('../controllers/buyerVendorsController');

router.use(authenticateJWT);

router.get('/nearby', buyerVendorsController.getNearbyVendors);
router.get('/live-map', buyerVendorsController.getLiveMapVendors);
router.post('/scan-qr', buyerVendorsController.scanQr);
router.get('/categories', buyerVendorsController.getCategories);
router.get('/:id', buyerVendorsController.getVendorDetails);
router.get('/:id/products', buyerVendorsController.getVendorProducts);
router.get('/:id/route', buyerVendorsController.getVendorRoute);
router.get('/:id/eta', buyerVendorsController.getVendorETA);

module.exports = router;
