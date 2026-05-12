const express = require('express');
const router = express.Router();
const Reel = require('../models/Reel');
const auth = require('../middleware/auth');
const { upload } = require('../config/cloudinary');

// Get all reels
router.get('/', async (req, res) => {
  try {
    const reels = await Reel.find().populate('seller', 'name avatar');
    res.json(reels);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Post reel (Seller only)
router.post('/', auth, upload.single('video'), async (req, res) => {
  try {
    if (req.user.role !== 'seller') return res.status(403).json({ message: 'Only sellers can post reels' });

    const reel = new Reel({
      seller: req.user.id,
      videoUrl: req.file.path,
      caption: req.body.caption
    });
    await reel.save();
    res.status(201).json(reel);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
