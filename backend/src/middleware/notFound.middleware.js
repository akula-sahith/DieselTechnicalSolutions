import { sendError } from '../utils/response.js';

export const notFoundHandler = (req, res) => {
  return sendError(res, 'Route not found.', {}, 404);
};
