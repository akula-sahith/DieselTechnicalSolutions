import express from 'express';
import {
  createEstimate,
  deleteEstimate,
  getEstimateById,
  getEstimates,
  updateEstimate,
  convertEstimateToInvoice,
  convertEstimateToDeliveryChallan,
} from '../controllers/estimate.controller.js';

const router = express.Router();

router.post('/', createEstimate);
router.get('/', getEstimates);
router.get('/:id', getEstimateById);
router.put('/:id', updateEstimate);
router.delete('/:id', deleteEstimate);
router.post('/:id/convert-to-invoice', convertEstimateToInvoice);
router.post('/:id/convert-to-delivery-challan', convertEstimateToDeliveryChallan);

export default router;
