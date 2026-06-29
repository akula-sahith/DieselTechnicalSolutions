import express from 'express';
import { createAgreement, deleteAgreement, getAgreementById, getAgreements, updateAgreement } from '../controllers/agreement.controller.js';
import { agreementUpload } from '../config/multer.js';

const router = express.Router();

router.post('/', agreementUpload, createAgreement);
router.get('/', getAgreements);
router.get('/:id', getAgreementById);
router.put('/:id', agreementUpload, updateAgreement);
router.delete('/:id', deleteAgreement);

export default router;
