import express from 'express';
import uploadToCloudinary from '../services/upload.service.js';
import { sendSuccess, sendError } from '../utils/response.js';
import upload from '../config/multer.js';

const router = express.Router();

router.post('/test-upload', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return sendError(res, 'Image file is required.', {}, 400);
    }

    const url = await uploadToCloudinary(req.file, 'efsr/test');

    return sendSuccess(res, 'Cloudinary upload successful.', { url }, 200);
  } catch (error) {
    return sendError(res, 'Cloudinary upload failed.', { details: error.message }, 500);
  }
});

export default router;
