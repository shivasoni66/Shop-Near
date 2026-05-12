const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const multer = require('multer');
require('dotenv').config();

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'shop-near',
<<<<<<< HEAD
    resource_type: 'auto',
    allowed_formats: ['jpg', 'png', 'jpeg', 'mp4', 'mov', 'avi', 'mkv', 'webm']
=======
    resource_type: 'auto', // This allows both images and videos
    allowed_formats: ['jpg', 'png', 'mp4', 'mov', 'avi', 'mkv', 'webm'],
    transformation: [{ quality: 'auto' }]
>>>>>>> cdcbe53 (Fix backend crash, improve UI aesthetics, and resolve login/reels screen issues)
  }
});

const upload = multer({ storage: storage });

module.exports = { cloudinary, upload };
