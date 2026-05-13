const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const auth = require('../middleware/auth');

// Place order
router.post('/', auth, async (req, res) => {
  try {
    const { productId, sellerId, amount, paymentMethod } = req.body;
    const order = new Order({
      product: productId,
      buyer: req.user.id,
      seller: sellerId,
      amount,
      paymentMethod
    });
    await order.save();
    
    // Populate for response
    const populatedOrder = await Order.findById(order._id)
      .populate('product')
      .populate('buyer', 'name location')
      .populate('seller', 'name');

    // Notify seller via Socket.IO
    req.io.emit(`new_order_${sellerId}`, populatedOrder); 
    
    res.status(201).json(populatedOrder);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get orders (for buyer or seller)
router.get('/', auth, async (req, res) => {
  try {
    let query = {};
    if (req.user.role === 'buyer') query.buyer = req.user.id;
    else query.seller = req.user.id;

    const orders = await Order.find(query)
      .populate('product')
      .populate('buyer', 'name location')
      .populate('seller', 'name');
    res.json(orders);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update order status (Seller only)
router.patch('/:id/status', auth, async (req, res) => {
  try {
    const { status } = req.body;
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: 'Order not found' });
    
    if (order.seller.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    order.status = status;
    order.updatedAt = Date.now();
    await order.save();
    
    // Notify buyer via Socket.IO
    req.io.emit(`order_status_update_${order.buyer}`, order);
    
    res.json(order);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
