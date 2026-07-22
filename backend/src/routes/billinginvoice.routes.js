import express from 'express';
import {
  createBillingInvoice,
  deleteBillingInvoice,
  getBillingInvoiceById,
  getBillingInvoices,
  updateBillingInvoice,
} from '../controllers/billinginvoice.controller.js';

const router = express.Router();

router.post('/', createBillingInvoice);
router.get('/', getBillingInvoices);
router.get('/:id', getBillingInvoiceById);
router.put('/:id', updateBillingInvoice);
router.delete('/:id', deleteBillingInvoice);

export default router;
