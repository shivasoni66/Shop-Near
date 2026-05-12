const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const multer = require('multer');
require('dotenv').config();

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// Single unified storage for all media (images & videos)
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'shop-near',
    resource_type: 'auto', // This handles both image and video automatically
    allowed_formats: ['jpg', 'png', 'jpeg', 'mp4', 'mov', 'avi', 'mkv', 'webm']
  }
});

const upload = multer({ storage: storage });

module.exports = { cloudinary, upload };
