import dotenv from 'dotenv';
import { v2 as cloudinary } from 'cloudinary';

dotenv.config();

const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
const apiKey = process.env.CLOUDINARY_API_KEY;
const apiSecret = process.env.CLOUDINARY_API_SECRET;

cloudinary.config({
  cloud_name: cloudName,
  api_key: apiKey,
  api_secret: apiSecret,
});

console.log('[Cloudinary] Configuration loaded for cloud:', cloudName || 'unknown');
console.log('[Cloudinary] API key present:', Boolean(apiKey));
console.log('[Cloudinary] API secret present:', Boolean(apiSecret));

if (!cloudName || !apiKey || !apiSecret) {
  console.warn('[Cloudinary] Missing one or more Cloudinary configuration values. Uploads will fail until they are set.');
}

export default cloudinary;
