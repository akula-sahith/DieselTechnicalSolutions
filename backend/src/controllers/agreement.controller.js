import Agreement from '../models/agreement.model.js';
import uploadToCloudinary from '../services/upload.service.js';
import { sendSuccess, sendError } from '../utils/response.js';
import { calculateAgreementTotals, formatOfferNumber, numberToWords } from '../utils/agreement.utils.js';

const getAgreementPayload = (req) => {
  const rawPayload = req.body?.agreement ?? req.body;
  if (!rawPayload) {
    return null;
  }

  return typeof rawPayload === 'string' ? JSON.parse(rawPayload) : rawPayload;
};

const buildDescriptionItems = (items = []) => {
  return items.map((item) => {
    const quantity = Number(item.quantity || 0);
    const rate = Number(item.rate || 0);
    return {
      description: item.description || '',
      quantity,
      rate,
      subTotal: Number((quantity * rate).toFixed(2)),
    };
  });
};

const generateOfferNumber = async () => {
  const latestAgreement = await Agreement.findOne().sort({ createdAt: -1 }).select('offerNumber').lean();

  if (!latestAgreement?.offerNumber) {
    return formatOfferNumber(1);
  }

  const currentSequence = Number(latestAgreement.offerNumber.split('/').pop());
  return formatOfferNumber(Number.isNaN(currentSequence) ? 1 : currentSequence + 1);
};

export const createAgreement = async (req, res) => {
  try {
    const agreementPayload = getAgreementPayload(req);

    if (!agreementPayload) {
      return sendError(res, 'Agreement payload is required.', {}, 400);
    }

    const customerSignatureFile = req.files?.customerSignature?.[0];

    if (!customerSignatureFile) {
      return sendError(res, 'Customer signature is required.', {}, 400);
    }

    const descriptionItems = buildDescriptionItems(agreementPayload.descriptionItems || []);

    if (!descriptionItems.length) {
      return sendError(res, 'At least one description item is required.', {}, 400);
    }

    if (!agreementPayload.customerName || !agreementPayload.completeAddress || !agreementPayload.contactPerson || !agreementPayload.mobileNumber) {
      return sendError(res, 'Customer name, address, contact person and mobile number are required.', {}, 400);
    }

    const invalidItem = descriptionItems.find((item) => !item.description || item.quantity <= 0 || item.rate <= 0);
    if (invalidItem) {
      return sendError(res, 'Each description item must have a valid description, quantity greater than zero, and rate greater than zero.', {}, 400);
    }

    const gstPercentage = Number(agreementPayload.gstPercentage || 0);
    if (gstPercentage < 0 || gstPercentage > 100) {
      return sendError(res, 'GST percentage must be between 0 and 100.', {}, 400);
    }

    const customerSignatureUrl = await uploadToCloudinary(customerSignatureFile, 'dts/agreements/signatures');

    const totals = calculateAgreementTotals(descriptionItems, {
      gstRequired: agreementPayload.gstRequired,
      gstPercentage,
    });

    const agreementDocument = {
      documentType: agreementPayload.documentType || 'Agreement',
      offerNumber: await generateOfferNumber(),
      date: agreementPayload.date ? new Date(agreementPayload.date) : new Date(),
      customerName: agreementPayload.customerName,
      completeAddress: agreementPayload.completeAddress,
      contactPerson: agreementPayload.contactPerson,
      mobileNumber: agreementPayload.mobileNumber,
      descriptionItems,
      gstRequired: agreementPayload.gstRequired === true || agreementPayload.gstRequired === 'true',
      gstPercentage,
      totalBeforeGST: totals.totalBeforeGST,
      gstAmount: totals.gstAmount,
      grandTotal: totals.grandTotal,
      amountInWords: numberToWords(totals.grandTotal),
      technicianSignatureUrl: agreementPayload.technicianSignatureUrl || 'https://res.cloudinary.com/dy5gs2egc/image/upload/v1782710059/efsr/signatures/i1ijhzyhgkmeig7v7cad.png',
      customerSignatureUrl,
      termsAndConditions: agreementPayload.termsAndConditions,
      paymentTerms: agreementPayload.paymentTerms,
      offerValidity: agreementPayload.offerValidity,
      notes: agreementPayload.notes,
      footerText: agreementPayload.footerText,
    };

    const agreement = await Agreement.create(agreementDocument);

    return sendSuccess(res, 'Agreement created successfully.', agreement, 201);
  } catch (error) {
    if (error instanceof SyntaxError) {
      return sendError(res, 'Invalid JSON payload.', { details: error.message }, 400);
    }

    return sendError(res, 'Failed to create agreement.', { details: error.message }, 500);
  }
};

export const getAgreements = async (req, res) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 10));
    const skip = (page - 1) * limit;
    const search = req.query.search || '';
    const documentType = req.query.documentType || '';
    const customerName = req.query.customerName || '';
    const mobileNumber = req.query.mobileNumber || '';
    const offerNumber = req.query.offerNumber || '';
    const date = req.query.date || '';

    const query = {};

    if (search) {
      query.$or = [
        { offerNumber: { $regex: search, $options: 'i' } },
        { customerName: { $regex: search, $options: 'i' } },
        { mobileNumber: { $regex: search, $options: 'i' } },
        { documentType: { $regex: search, $options: 'i' } },
      ];
    }

    if (documentType) {
      query.documentType = documentType;
    }

    if (customerName) {
      query.customerName = { $regex: customerName, $options: 'i' };
    }

    if (mobileNumber) {
      query.mobileNumber = { $regex: mobileNumber, $options: 'i' };
    }

    if (offerNumber) {
      query.offerNumber = { $regex: offerNumber, $options: 'i' };
    }

    if (date) {
      const start = new Date(date);
      const end = new Date(date);
      end.setDate(end.getDate() + 1);
      query.date = { $gte: start, $lt: end };
    }

    const [agreements, total] = await Promise.all([
      Agreement.find(query).sort({ createdAt: -1 }).skip(skip).limit(limit),
      Agreement.countDocuments(query),
    ]);

    return sendSuccess(res, 'Agreements retrieved successfully.', {
      agreements,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    return sendError(res, 'Failed to fetch agreements.', { details: error.message }, 500);
  }
};

export const getAgreementById = async (req, res) => {
  try {
    const agreement = await Agreement.findById(req.params.id);

    if (!agreement) {
      return sendError(res, 'Agreement not found.', {}, 404);
    }

    return sendSuccess(res, 'Agreement retrieved successfully.', agreement);
  } catch (error) {
    return sendError(res, 'Failed to fetch agreement.', { details: error.message }, 500);
  }
};

export const updateAgreement = async (req, res) => {
  try {
    const agreementPayload = getAgreementPayload(req);
    if (!agreementPayload) {
      return sendError(res, 'Agreement payload is required.', {}, 400);
    }

    const agreement = await Agreement.findById(req.params.id);
    if (!agreement) {
      return sendError(res, 'Agreement not found.', {}, 404);
    }

    const descriptionItems = buildDescriptionItems(agreementPayload.descriptionItems || agreement.descriptionItems || []);

    const totals = calculateAgreementTotals(descriptionItems, {
      gstRequired: agreementPayload.gstRequired ?? agreement.gstRequired,
      gstPercentage: agreementPayload.gstPercentage ?? agreement.gstPercentage,
    });

    const updatePayload = {
      documentType: agreementPayload.documentType || agreement.documentType,
      date: agreementPayload.date ? new Date(agreementPayload.date) : agreement.date,
      customerName: agreementPayload.customerName || agreement.customerName,
      completeAddress: agreementPayload.completeAddress || agreement.completeAddress,
      contactPerson: agreementPayload.contactPerson || agreement.contactPerson,
      mobileNumber: agreementPayload.mobileNumber || agreement.mobileNumber,
      descriptionItems,
      gstRequired: agreementPayload.gstRequired ?? agreement.gstRequired,
      gstPercentage: agreementPayload.gstPercentage ?? agreement.gstPercentage,
      totalBeforeGST: totals.totalBeforeGST,
      gstAmount: totals.gstAmount,
      grandTotal: totals.grandTotal,
      amountInWords: numberToWords(totals.grandTotal),
      termsAndConditions: agreementPayload.termsAndConditions ?? agreement.termsAndConditions,
      paymentTerms: agreementPayload.paymentTerms ?? agreement.paymentTerms,
      offerValidity: agreementPayload.offerValidity ?? agreement.offerValidity,
      notes: agreementPayload.notes ?? agreement.notes,
      footerText: agreementPayload.footerText ?? agreement.footerText,
    };

    if (req.files?.customerSignature?.[0]) {
      updatePayload.customerSignatureUrl = await uploadToCloudinary(req.files.customerSignature[0], 'dts/agreements/signatures');
    }

    const updatedAgreement = await Agreement.findByIdAndUpdate(req.params.id, updatePayload, { new: true, runValidators: true });

    return sendSuccess(res, 'Agreement updated successfully.', updatedAgreement);
  } catch (error) {
    return sendError(res, 'Failed to update agreement.', { details: error.message }, 500);
  }
};

export const deleteAgreement = async (req, res) => {
  try {
    const agreement = await Agreement.findByIdAndDelete(req.params.id);

    if (!agreement) {
      return sendError(res, 'Agreement not found.', {}, 404);
    }

    return sendSuccess(res, 'Agreement deleted successfully.', {});
  } catch (error) {
    return sendError(res, 'Failed to delete agreement.', { details: error.message }, 500);
  }
};
