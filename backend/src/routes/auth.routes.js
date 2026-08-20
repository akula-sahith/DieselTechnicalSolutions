import express from 'express';
import {
  login,
  registerReporter,
  getReporters,
  deleteReporter,
} from '../controllers/auth.controller.js';

const router = express.Router();

router.post('/login', login);
router.post('/register-reporter', registerReporter);
router.get('/reporters', getReporters);
router.delete('/reporters/:id', deleteReporter);

export default router;
