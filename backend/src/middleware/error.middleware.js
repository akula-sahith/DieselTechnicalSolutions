import { sendError } from '../utils/response.js';

export const errorHandler = (err, req, res, next) => {
  if (res.headersSent) {
    return next(err);
  }

  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return sendError(res, 'Invalid JSON payload.', { details: err.message }, 400);
  }

  if (err.code === 'LIMIT_FILE_SIZE') {
    return sendError(res, 'File too large. Maximum size is 5MB.', { details: err.message }, 413);
  }

  if (err.message === 'Only image files are allowed.') {
    return sendError(res, err.message, { details: err.message }, 400);
  }

  return sendError(res, 'Internal server error.', { details: err.message || 'Unexpected error' }, 500);
};
