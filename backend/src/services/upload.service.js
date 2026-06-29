import cloudinary from '../config/cloudinary.js';

const uploadToCloudinary = async (file, folder) => {
  const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
  const apiKey = process.env.CLOUDINARY_API_KEY;
  const apiSecret = process.env.CLOUDINARY_API_SECRET;

  if (!cloudName || !apiKey || !apiSecret) {
    throw new Error('Cloudinary configuration is incomplete. Check CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and CLOUDINARY_API_SECRET.');
  }

  if (!file) {
    console.error('[Cloudinary] No file provided for upload.');
    throw new Error('No file provided for upload.');
  }

  console.log(`[Cloudinary] Uploading file to folder: ${folder} | mimetype: ${file.mimetype} | size: ${file.size}`);

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: 'image',
      },
      (error, result) => {
        if (error) {
          console.error('[Cloudinary] Upload failed:', error.message || error);
          reject(error);
          return;
        }

        console.log('[Cloudinary] Upload successful. URL:', result.secure_url);
        resolve(result.secure_url);
      }
    );

    stream.end(file.buffer);
  });
};

export default uploadToCloudinary;
