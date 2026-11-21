const multer = require('multer');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const ApiResponse = require('../../utils/ApiResponse');
const ApiError = require('../../utils/ApiError');

const ALLOWED_MIMES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_SIZE = 5 * 1024 * 1024; // 5 MB
const UPLOAD_DIR = path.join(__dirname, '../../../uploads');

// A fresh checkout ignores `uploads/`, so create it before multer writes to it.
fs.mkdirSync(UPLOAD_DIR, { recursive: true });

// Never trust the client's filename extension: a file named `x.html` with an
// image MIME type would otherwise be served as HTML from the API origin.
const EXT_BY_MIME = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
};

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, UPLOAD_DIR);
  },
  filename: (_req, file, cb) => {
    cb(null, `${crypto.randomUUID()}${EXT_BY_MIME[file.mimetype] || '.jpg'}`);
  },
});

const fileFilter = (_req, file, cb) => {
  if (ALLOWED_MIMES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(
      new ApiError(
        400,
        'Only JPEG, PNG, and WebP images are allowed',
        [],
        'INVALID_IMAGE_TYPE',
      ),
      false,
    );
  }
};

const upload = multer({ storage, fileFilter, limits: { fileSize: MAX_SIZE } });

const uploadImage = (req, res, next) => {
  try {
    if (!req.file) {
      throw ApiError.badRequest('No image file provided');
    }
    const baseUrl = (
      process.env.PUBLIC_BASE_URL || `${req.protocol}://${req.get('host')}`
    ).replace(/\/+$/, '');
    return ApiResponse.success(
      res,
      {
        url: `${baseUrl}/uploads/${req.file.filename}`,
        path: `/uploads/${req.file.filename}`,
      },
      201,
    );
  } catch (err) {
    next(err);
  }
};

module.exports = { upload, uploadImage };
