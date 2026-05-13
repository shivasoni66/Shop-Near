const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Product = require('../models/Product');
const Order = require('../models/Order');
const auth = require('../middleware/auth');

// Get all sellers
router.get('/', async (req, res) => {
  try {
    const sellers = await User.find({ role: 'seller' }).select('-password');
    res.json(sellers);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get seller analytics
router.get('/analytics', auth, async (req, res) => {
  try {
    if (req.user.role !== 'seller') {
      return res.status(403).json({ message: 'Access denied. Only sellers can view analytics.' });
    }

    const period = req.query.period || 'week';
    let dateLimit = new Date();
    
    if (period === 'month') {
      dateLimit.setMonth(dateLimit.getMonth() - 1);
    } else if (period === 'year') {
      dateLimit.setFullYear(dateLimit.getFullYear() - 1);
    } else {
      dateLimit.setDate(dateLimit.getDate() - 7);
    }

    const orders = await Order.find({ 
      seller: req.user.id,
      orderDate: { $gte: dateLimit } 
    });

    const totalOrders = orders.length;
    const totalRevenue = orders.reduce((sum, order) => sum + order.amount, 0);
    const pendingOrders = orders.filter(o => o.status === 'Pending').length;
    const deliveredOrders = orders.filter(o => o.status === 'Delivered').length;

    // Daily/Monthly Revenue for chart
    const dailyRevenue = [];
    const iterations = period === 'year' ? 12 : period === 'month' ? 30 : 7;
    
    for (let i = iterations - 1; i >= 0; i--) {
      const date = new Date();
      date.setHours(0, 0, 0, 0);
      
      if (period === 'year') {
        date.setMonth(date.getMonth() - i);
        date.setDate(1);
        const nextDate = new Date(date);
        nextDate.setMonth(nextDate.getMonth() + 1);
        
        const monthRevenue = orders
          .filter(o => o.orderDate >= date && o.orderDate < nextDate)
          .reduce((sum, order) => sum + order.amount, 0);
        
        dailyRevenue.push({
          day: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.getMonth()],
          amount: monthRevenue
        });
      } else {
        date.setDate(date.getDate() - i);
        const nextDate = new Date(date);
        nextDate.setDate(nextDate.getDate() + 1);

        const dayRevenue = orders
          .filter(o => o.orderDate >= date && o.orderDate < nextDate)
          .reduce((sum, order) => sum + order.amount, 0);
        
        dailyRevenue.push({
          day: period === 'month' ? date.getDate().toString() : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.getDay()],
          amount: dayRevenue
        });
      }
    }

    // Top Products
    const products = await Product.find({ seller: req.user.id });
    const topProducts = products.map(p => {
      const sold = orders.filter(o => o.productId && o.productId.toString() === p._id.toString()).length;
      return {
        id: p._id,
        name: p.name,
        sold: sold,
        revenue: sold * p.price,
        image: p.images[0] || ''
      };
    }).sort((a, b) => b.sold - a.sold).slice(0, 3);

    res.json({
      totalOrders,
      totalRevenue,
      pendingOrders,
      deliveredOrders,
      dailyRevenue,
      topProducts,
      conversionRate: '4.2%',
      avgOrderValue: totalOrders > 0 ? Math.round(totalRevenue / totalOrders) : 0,
      rating: 4.8
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get seller products
router.get('/products', auth, async (req, res) => {
  try {
    if (req.user.role !== 'seller') {
      return res.status(403).json({ message: 'Access denied. Only sellers can view their products.' });
    }
    const products = await Product.find({ seller: req.user.id });
    res.json(products);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
