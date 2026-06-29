import express from 'express';
import { createReport, getReportById, getReports } from '../controllers/report.controller.js';
import { reportUpload } from '../config/multer.js';

const router = express.Router();

router.post('/', reportUpload, createReport);
router.get('/', getReports);
router.get('/:id', getReportById);

export default router;
