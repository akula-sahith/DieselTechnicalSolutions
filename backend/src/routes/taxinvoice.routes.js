import express from 'express';
import {
  createTaxInvoice,
  deleteTaxInvoice,
  getTaxInvoiceById,
  getTaxInvoices,
  updateTaxInvoice,
  updatePaymentStatus,
} from '../controllers/taxinvoice.controller.js';

const router = express.Router();

router.post('/', createTaxInvoice);
router.get('/', getTaxInvoices);
router.get('/:id', getTaxInvoiceById);
router.put('/:id', updateTaxInvoice);
router.patch('/:id/payment', updatePaymentStatus);
router.delete('/:id', deleteTaxInvoice);

export default router;
