const express = require('express');
const router = express.Router();
const Product = require('../models/Product');
const auth = require('../middleware/auth');
const { upload } = require('../config/cloudinary');

// Get all products (with optional filters)
router.get('/', async (req, res) => {
  try {
    const { category, query } = req.query;
    let filter = {};
    
    if (category) {
      filter.category = { $regex: category, $options: 'i' };
    }
    
    if (query) {
      filter.$or = [
        { name: { $regex: query, $options: 'i' } },
        { description: { $regex: query, $options: 'i' } },
        { tags: { $in: [new RegExp(query, 'i')] } }
      ];
    }

    const products = await Product.find(filter).populate('seller', 'name avatar');
    res.json(products);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get single product
router.get('/:id', async (req, res) => {
  try {
    const product = await Product.findById(req.params.id).populate('seller', 'name avatar');
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.json(product);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create product (Seller only)
router.post('/', auth, upload.array('images', 5), async (req, res) => {
  try {
    console.log('--- Incoming Product Creation ---');
    console.log('User:', req.user.id);
    console.log('Body data:', req.body);

    if (req.user.role !== 'seller') {
      console.log('❌ Denied: User is not a seller');
      return res.status(403).json({ message: 'Only sellers can add products' });
    }

    if (!req.files || req.files.length === 0) {
      console.log('❌ Error: No images received');
      return res.status(400).json({ message: 'At least one image is required' });
    }

    const imageUrls = req.files.map(file => file.path);
    console.log('✅ Images uploaded to Cloudinary:', imageUrls);

    const product = new Product({
      name: req.body.name,

      description: req.body.description,

      category: req.body.category,

      price: Number(req.body.price),

      stock: Number(req.body.stock),

      tags: req.body.tags
        ? req.body.tags.split(',')
        : [],

      images: imageUrls,

      seller: req.user.id
    });

    await product.save();
    console.log('✅ Product saved in MongoDB:', product._id);
    res.status(201).json(product);
  } catch (err) {
    console.error('🔥 Server Error during product creation:', err);
    res.status(500).json({
      message: 'Failed to create product',
      error: err.message,
      stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
  }
});

module.exports = router;
