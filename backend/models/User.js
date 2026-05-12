const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['buyer', 'seller'], default: 'buyer' },
  avatar: { type: String, default: '' },
  handle: { type: String, default: '' },
  location: { type: String, default: '' },
  bio: { type: String, default: '' },
  phone: { type: String, default: '' },
  points: { type: Number, default: 0 },
  ordersCount: { type: Number, default: 0 },
  followingCount: { type: Number, default: 0 },
  reviewsCount: { type: Number, default: 0 },
  isVerified: { type: Boolean, default: false },
  followers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  following: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  settings: {
    liveSessionAlerts: { type: Boolean, default: true },
    orderUpdates: { type: Boolean, default: true },
    offersDeals: { type: Boolean, default: true },
    chatMessages: { type: Boolean, default: false },
    biometricLogin: { type: Boolean, default: true },
    publicProfile: { type: Boolean, default: true },
  },
  createdAt: { type: Date, default: Date.now }
});

userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
