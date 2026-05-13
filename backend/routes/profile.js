const express = require('express');
const router = express.Router();
const User = require('../models/User');
const auth = require('../middleware/auth');
const { upload } = require('../config/cloudinary');
const Review = require('../models/Review');
const Order = require('../models/Order');
const Product = require('../models/Product');

// Get current user profile
router.get('/', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });

    // Calculate dynamic counts
    const reviewsCount = await Review.countDocuments({ user: req.user.id });
    const wishlistCount = user.wishlist ? user.wishlist.length : 0;
    const followingCount = user.following ? user.following.length : 0;
    const ordersCount = await Order.countDocuments({ buyer: req.user.id });

    // Merge counts into response
    const userData = user.toObject();
    userData.id = userData._id;
    userData.reviewsCount = reviewsCount;
    userData.wishlistCount = wishlistCount;
    userData.followingCount = followingCount;
    userData.ordersCount = ordersCount;

    res.json(userData);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get profile by ID
router.get('/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update profile
router.put('/', auth, upload.single('avatar'), async (req, res) => {
  try {
    const updates = { ...req.body };
    if (req.file) {
      updates.avatar = req.file.path;
    }

    // Sanitize input
    delete updates._id;
    delete updates.id;
    delete updates.email;
    delete updates.password;

    const user = await User.findByIdAndUpdate(
      req.user.id, 
      { $set: updates }, 
      { new: true, runValidators: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(user);
  } catch (err) {
    console.error('Profile Update Error:', err);
    res.status(500).json({ 
      message: 'Failed to update profile', 
      error: err.message 
    });
  }
});

// Get user wishlist products
router.get('/wishlist', auth, async (req, res) => {
  try {
    console.log(`Fetching wishlist for user: ${req.user.id}`);
    const user = await User.findById(req.user.id).populate('wishlist');
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Filter out any products that might have been deleted but are still in wishlist array
    const validWishlist = (user.wishlist || []).filter(item => item != null);
    
    console.log(`Found ${validWishlist.length} valid items in wishlist`);
    res.json(validWishlist);
  } catch (err) {
    console.error('CRITICAL: Wishlist Fetch Error:', err);
    res.status(500).json({ 
      message: 'Server error while fetching wishlist',
      error: err.message 
    });
  }
});

// Get user reviews
router.get('/reviews', auth, async (req, res) => {
  try {
    const reviews = await Review.find({ user: req.user.id }).populate('product');
    res.json(reviews);
  } catch (err) {
    console.error('Reviews Error:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
