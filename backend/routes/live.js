const express = require('express');
const router = express.Router();
const LiveSession = require('../models/LiveSession');
const auth = require('../middleware/auth');
const { upload } = require('../config/cloudinary');

// Get all live sessions (With auto-cleanup for ghost sessions)
router.get('/', async (req, res) => {
  try {
    // Auto-end sessions that are older than 1 hour (ghost sessions)
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    await LiveSession.updateMany(
      { isLive: true, createdAt: { $lt: oneHourAgo } },
      { $set: { isLive: false, endedAt: Date.now() } }
    );

    const sessions = await LiveSession.find({ isLive: true })
      .populate('seller', 'name avatar');
    res.json(sessions);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Admin cleanup route to clear all live sessions manually
router.get('/cleanup-all-force', async (req, res) => {
  try {
    await LiveSession.updateMany({}, { $set: { isLive: false, endedAt: Date.now() } });
    res.json({ message: 'All sessions marked as ended' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Start live session (Seller only)
router.post('/', auth, upload.single('thumbnail'), async (req, res) => {
  try {
    if (req.user.role !== 'seller') return res.status(403).json({ message: 'Only sellers can go live' });

    const session = new LiveSession({
      seller: req.user.id,
      title: req.body.title,
      category: req.body.category,
      thumbnail: req.file ? req.file.path : ''
    });
    
    await session.save();
    
    // Populate seller for the broadcast
    const populatedSession = await LiveSession.findById(session._id).populate('seller', 'name avatar');
    
    // Broadcast to all users that a new live session started
    req.io.emit('live_update', { action: 'started', session: populatedSession });
    
    res.status(201).json(session);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// End live session (Seller only)
router.put('/:id/end', auth, async (req, res) => {
  try {
    const session = await LiveSession.findById(req.params.id);
    if (!session) return res.status(404).json({ message: 'Session not found' });
    if (session.seller.toString() !== req.user.id) return res.status(403).json({ message: 'Unauthorized' });

    session.isLive = false;
    session.endedAt = Date.now();
    await session.save();

    // Broadcast update
    req.io.emit('live_update', { action: 'ended', sessionId: session._id });

    res.json({ message: 'Session ended' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
