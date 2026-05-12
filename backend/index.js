const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const http = require('http');
const path = require('path');
const { Server } = require('socket.io');
const connectDB = require('./config/db');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware to pass io to routes
app.use((req, res, next) => {
  req.io = io;
  next();
});

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Range'],
  exposedHeaders: ['Content-Range', 'Accept-Ranges', 'Content-Length', 'Content-Type'],
}));
app.use(express.json());

// Serve uploaded files
app.use('/uploads', (req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Accept-Ranges', 'bytes');
  next();
}, express.static(path.join(__dirname, 'uploads')));

// MongoDB Connection
connectDB();

// Routes
const authRoutes = require('./routes/auth');
const productRoutes = require('./routes/products');
const orderRoutes = require('./routes/orders');
const liveRoutes = require('./routes/live');
const reelRoutes = require('./routes/reels');
const chatRoutes = require('./routes/chat');
const profileRoutes = require('./routes/profile');
const sellerRoutes = require('./routes/sellers');

app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/live', liveRoutes);
app.use('/api/reels', reelRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/sellers', sellerRoutes);

// Socket.IO Logic
io.on('connection', (socket) => {
  console.log('A user connected:', socket.id);

  socket.on('join_room', (roomId) => {
    socket.join(roomId);
    console.log(`User joined room: ${roomId}`);
  });

  socket.on('live_chat', (data) => {
    io.to(data.roomId).emit('receive_live_chat', data);
  });

  socket.on('live_reaction', (data) => {
    io.to(data.roomId).emit('receive_live_reaction', data);
  });

  socket.on('order_update', (data) => {
    io.emit('order_notification', data);
  });

  socket.on('disconnect', () => {
    console.log('User disconnected');
  });
});

// Routes Placeholder
app.get('/', (req, res) => {
  res.send('Shop-Near Backend API is running...');
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('🔥 Global Error Handler:', err);
  res.status(500).json({
    message: err.message || 'An internal server error occurred',
    error: err.name || 'Error',
    details: err.errors || err,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });
});

// Start Server
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
