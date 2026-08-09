import express from 'express';
import {
  createTaxInvoice,
  deleteTaxInvoice,
  getTaxInvoiceById,
  getTaxInvoices,
  updateTaxInvoice,
  updatePaymentStatus,
  addTaxInvoicePayment,
} from '../controllers/taxinvoice.controller.js';

const router = express.Router();

router.post('/', createTaxInvoice);
router.get('/', getTaxInvoices);
router.get('/:id', getTaxInvoiceById);
router.put('/:id', updateTaxInvoice);
router.patch('/:id/payment', updatePaymentStatus);
router.post('/:id/payments', addTaxInvoicePayment);
router.delete('/:id', deleteTaxInvoice);

export default router;
