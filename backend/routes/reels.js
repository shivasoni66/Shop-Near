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
router.post('/', auth, (req, res, next) => {
  upload.single('video')(req, res, (err) => {
    if (err) {
      console.error('Multer/Cloudinary Error:', err);
      return res.status(500).json({ error: err.message || 'Upload failed', details: err });
    }
    next();
  });
}, async (req, res) => {
  try {
    // Temporarily allow anyone to post reels for testing purposes
    // if (req.user.role !== 'seller') return res.status(403).json({ message: 'Only sellers can post reels' });

    console.log('Post Reel Request Received');
    console.log('File:', req.file);
    console.log('Body:', req.body);

    if (!req.file) {
      console.log('Error: No file in request');
      return res.status(400).json({ message: 'No video file uploaded' });
    }

    // multer-storage-cloudinary sets req.file.path to the Cloudinary secure URL
    const videoUrl = req.file.path;
    // if (req.user.role !== 'seller') return res.status(403).json({ message: 'Only sellers can post reels' });

    const reel = new Reel({
      seller: req.user.id,
      videoUrl: req.file.path,
      caption: req.body.caption
    });
    await reel.save();

    // Populate seller so the frontend gets name + avatar immediately
    await reel.populate('seller', 'name avatar');

    // Broadcast to all connected clients in real time
    if (req.io) {
      req.io.emit('new_reel', reel);
    }

    
    // Emit real-time update
    req.io.emit('reel_update', { action: 'created', reel: reel });
    
    res.status(201).json(reel);
  } catch (err) {
    console.error('Reel Upload Error:', err);
    res.status(500).json({ error: err.message });
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

// Get seller's own reels
router.get('/seller/me', auth, async (req, res) => {
  try {
    const reels = await Reel.find({ seller: req.user.id }).populate('seller', 'name avatar');
    res.json(reels);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Edit a reel caption
router.put('/:id', auth, async (req, res) => {
  try {
    const reel = await Reel.findById(req.params.id);
    if (!reel) return res.status(404).json({ message: 'Reel not found' });
    
    // Check authorization
    if (reel.seller.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to edit this reel' });
    }

    reel.caption = req.body.caption || reel.caption;
    await reel.save();

    await reel.populate('seller', 'name avatar');
    if (req.io) {
      req.io.emit('reel_updated', reel);
    }

    res.json(reel);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete a reel
router.delete('/:id', auth, async (req, res) => {
  try {
    const reel = await Reel.findById(req.params.id);
    if (!reel) return res.status(404).json({ message: 'Reel not found' });

    // Check authorization
    if (reel.seller.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to delete this reel' });
    }

    // Optionally delete from cloudinary using cloudinary.uploader.destroy
    // if we stored the public_id, but here we just delete from db.
    await reel.deleteOne();

    if (req.io) {
      req.io.emit('reel_deleted', req.params.id);
    }

    res.json({ message: 'Reel deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
