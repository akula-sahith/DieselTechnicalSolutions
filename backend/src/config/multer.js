import multer from 'multer';

const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
    return;
  }

  cb(new Error('Only image files are allowed.'), false);
};

const upload = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024,
  },
  fileFilter,
});

export const reportUpload = upload.fields([
  { name: 'technicianSignature', maxCount: 1 },
  { name: 'customerPhoto', maxCount: 1 },
]);

export default upload;
