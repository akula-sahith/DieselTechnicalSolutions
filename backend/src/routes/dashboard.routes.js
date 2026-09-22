import express from 'express';
import {
  getDashboardStats,
  getMonthlyDetail,
  getWeekDocuments,
} from '../controllers/dashboard.controller.js';

const router = express.Router();

router.get('/stats', getDashboardStats);
router.get('/monthly-detail', getMonthlyDetail);
router.get('/week-documents', getWeekDocuments);

export default router;
