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

// Post reel
router.post('/', auth, upload.single('video'), async (req, res) => {
  try {
    // Temporarily allow anyone to post reels for testing purposes
    // if (req.user.role !== 'seller') return res.status(403).json({ message: 'Only sellers can post reels' });

    if (!req.file) {
      return res.status(400).json({ message: 'No video file uploaded' });
    }

    // multer-storage-cloudinary sets req.file.path to the Cloudinary secure URL
    const videoUrl = req.file.path;

    const reel = new Reel({
      seller: req.user.id,
      videoUrl,
      caption: req.body.caption
    });
    await reel.save();

    // Populate seller so the frontend gets name + avatar immediately
    await reel.populate('seller', 'name avatar');

    // Broadcast to all connected clients in real time
    if (req.io) {
      req.io.emit('new_reel', reel);
    }

    res.status(201).json(reel);
  } catch (err) {
    console.error('Reel upload error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Like/Unlike a reel
router.post('/:id/like', auth, async (req, res) => {
  try {
    const reel = await Reel.findById(req.params.id);
    if (!reel) return res.status(404).json({ message: 'Reel not found' });

    const index = reel.likes.indexOf(req.user.id);
    if (index === -1) {
      reel.likes.push(req.user.id);
    } else {
      reel.likes.splice(index, 1);
    }

    await reel.save();
    
    // Broadcast updated reel
    await reel.populate('seller', 'name avatar');
    if (req.io) {
      req.io.emit('reel_updated', reel);
    }

    res.json(reel);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Add a comment
router.post('/:id/comment', auth, async (req, res) => {
  try {
    const reel = await Reel.findById(req.params.id);
    if (!reel) return res.status(404).json({ message: 'Reel not found' });

    reel.comments.push({
      user: req.user.id,
      text: req.body.text
    });

    await reel.save();

    // Broadcast updated reel
    await reel.populate('seller', 'name avatar');
    await reel.populate('comments.user', 'name avatar'); // Populate comment authors
    if (req.io) {
      req.io.emit('reel_updated', reel);
    }

    res.json(reel);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get comments for a reel
router.get('/:id/comments', async (req, res) => {
  try {
    const reel = await Reel.findById(req.params.id).populate('comments.user', 'name avatar');
    if (!reel) return res.status(404).json({ message: 'Reel not found' });
    res.json(reel.comments);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
