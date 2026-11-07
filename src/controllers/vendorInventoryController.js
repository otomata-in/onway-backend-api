const prisma = require('../config/prisma');

async function getInventory(req, res) {
  try {
    const { profileId } = req.user;
    const products = await prisma.inventoryProduct.findMany({
      where: { vendorId: profileId, isDeleted: false }
    });
    return res.json({ success: true, data: products });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

async function addProduct(req, res) {
  try {
    const { profileId } = req.user;
    const { name, category, price, unit, inStock, stockLevel, imagePath } = req.body;
    
    const product = await prisma.inventoryProduct.create({
      data: {
        vendorId: profileId,
        name,
        category,
        price,
        unit,
        inStock,
        stockLevel,
        imagePath
      }
    });
    
    return res.json({ success: true, data: product });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

async function updateProduct(req, res) {
  try {
    const { profileId } = req.user;
    const { id } = req.params;
    const { name, category, price, unit, inStock, stockLevel, imagePath } = req.body;
    
    // verify ownership
    const product = await prisma.inventoryProduct.findFirst({
      where: { id, vendorId: profileId, isDeleted: false }
    });
    
    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found or unauthorized' });
    }
    
    const updated = await prisma.inventoryProduct.update({
      where: { id },
      data: { name, category, price, unit, inStock, stockLevel, imagePath }
    });
    
    return res.json({ success: true, data: updated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

async function deleteProduct(req, res) {
  try {
    const { profileId } = req.user;
    const { id } = req.params;
    
    // verify ownership
    const product = await prisma.inventoryProduct.findFirst({
      where: { id, vendorId: profileId, isDeleted: false }
    });
    
    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found or unauthorized' });
    }
    
    await prisma.inventoryProduct.update({
      where: { id },
      data: { isDeleted: true }
    });
    
    return res.json({ success: true, message: 'Product deleted successfully' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

module.exports = {
  getInventory,
  addProduct,
  updateProduct,
  deleteProduct
};
