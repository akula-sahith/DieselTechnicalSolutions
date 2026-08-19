import express from 'express';
import {
  createDeliveryChallan,
  deleteDeliveryChallan,
  getDeliveryChallanById,
  getDeliveryChallans,
  updateDeliveryChallan,
} from '../controllers/deliverychallan.controller.js';

const router = express.Router();

router.post('/', createDeliveryChallan);
router.get('/', getDeliveryChallans);
router.get('/:id', getDeliveryChallanById);
router.put('/:id', updateDeliveryChallan);
router.delete('/:id', deleteDeliveryChallan);

export default router;
