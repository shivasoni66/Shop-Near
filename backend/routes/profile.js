const express = require('express');
const router = express.Router();
const User = require('../models/User');
const auth = require('../middleware/auth');
const bcrypt = require('bcryptjs');
const { upload } = require('../config/cloudinary');

// Get current user profile
router.get('/', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json(user);
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

// Update profile (name, handle, bio, location, phone, avatar)
router.put('/', auth, upload.single('avatar'), async (req, res) => {
  try {
    console.log('--- Profile Update Request ---');
    console.log('User ID:', req.user.id);
    console.log('Body:', req.body);
    console.log('File:', req.file ? req.file.path : 'No file');

    const allowedFields = ['name', 'handle', 'location', 'bio', 'phone'];
    const updates = {};
    for (const field of allowedFields) {
      if (req.body[field] !== undefined && req.body[field] !== '') {
        updates[field] = req.body[field];
      }
    }

    if (req.file) {
      updates.avatar = req.file.path;
    } else if (req.body.avatar !== undefined && req.body.avatar !== '') {
      updates.avatar = req.body.avatar;
    }

    console.log('Updates to apply:', updates);

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ message: 'No fields to update' });
    }

    const user = await User.findByIdAndUpdate(req.user.id, updates, { new: true, runValidators: true }).select('-password');
    if (!user) {
      console.log('❌ User not found during update');
      return res.status(404).json({ message: 'User not found' });
    }

    console.log('✅ Profile updated successfully');
    res.json(user);
  } catch (err) {
    console.error('🔥 Error updating profile:', err);
    res.status(500).json({ 
      message: 'Failed to update profile', 
      error: err.message,
      stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
  }
});

// Update settings (toggles)
router.put('/settings', auth, async (req, res) => {
  try {
    const allowedSettings = ['liveSessionAlerts', 'orderUpdates', 'offersDeals', 'chatMessages', 'biometricLogin', 'publicProfile'];
    const settingsUpdate = {};
    for (const key of allowedSettings) {
      if (req.body[key] !== undefined) {
        settingsUpdate[`settings.${key}`] = req.body[key];
      }
    }

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { $set: settingsUpdate },
      { new: true }
    ).select('-password');

    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Change password
router.put('/password', auth, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Current and new password are required' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'New password must be at least 6 characters' });
    }

    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(400).json({ message: 'Current password is incorrect' });
    }

    user.password = newPassword;
    await user.save();

    res.json({ message: 'Password changed successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
