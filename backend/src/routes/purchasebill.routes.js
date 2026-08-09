import express from 'express';
import {
  createPurchaseBill,
  getPurchaseBills,
  getPurchaseBillById,
  updatePurchaseBill,
  deletePurchaseBill,
} from '../controllers/purchasebill.controller.js';
import upload from '../config/multer.js';

const router = express.Router();

router.post('/', upload.single('attachment'), createPurchaseBill);
router.get('/', getPurchaseBills);
router.get('/:id', getPurchaseBillById);
router.put('/:id', upload.single('attachment'), updatePurchaseBill);
router.delete('/:id', deletePurchaseBill);

export default router;
