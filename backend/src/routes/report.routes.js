import express from 'express';
import { createReport, deleteReport, getReportById, getReports, updateReport } from '../controllers/report.controller.js';
import { reportUpload } from '../config/multer.js';

const router = express.Router();

router.post('/', reportUpload, createReport);
router.get('/', getReports);
router.put('/:id', reportUpload, updateReport);
router.delete('/:id', deleteReport);
router.get('/:id', getReportById);

export default router;
