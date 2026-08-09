import PurchaseBill from '../models/purchasebill.model.js';
import uploadToCloudinary from '../services/upload.service.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const createPurchaseBill = async (req, res) => {
  try {
    const { vendorName, amount, taxAmount, billNumber, billDate, remarks, status } = req.body;

    if (!vendorName) {
      return sendError(res, 'Vendor name is required.', {}, 400);
    }
    if (amount === undefined || Number(amount) < 0) {
      return sendError(res, 'A valid positive bill amount is required.', {}, 400);
    }
    if (!req.file) {
      return sendError(res, 'Bill attachment (image or PDF) is required.', {}, 400);
    }

    // Upload attachment to Cloudinary
    let attachmentUrl = '';
    try {
      attachmentUrl = await uploadToCloudinary(req.file, 'dts/purchase-bills');
    } catch (uploadErr) {
      return sendError(res, 'Failed to upload bill attachment.', { details: uploadErr.message }, 500);
    }

    const billDocument = {
      vendorName: vendorName.trim(),
      amount: Number(amount),
      taxAmount: taxAmount ? Number(taxAmount) : 0,
      billNumber: billNumber ? billNumber.trim() : '',
      billDate: billDate ? new Date(billDate) : new Date(),
      attachmentUrl,
      remarks: remarks || '',
      status: status || 'pending',
    };

    const purchaseBill = await PurchaseBill.create(billDocument);

    return sendSuccess(res, 'Purchase Bill created successfully.', purchaseBill, 201);
  } catch (error) {
    return sendError(res, 'Failed to create Purchase Bill.', { details: error.message }, 500);
  }
};

export const getPurchaseBills = async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.max(1, parseInt(req.query.limit) || 10);
    const skip = (page - 1) * limit;

    const query = {};

    if (req.query.search) {
      query.$text = { $search: req.query.search };
    }

    if (req.query.status) {
      query.status = req.query.status;
    }

    const total = await PurchaseBill.countDocuments(query);
    const bills = await PurchaseBill.find(query)
      .sort({ billDate: -1, createdAt: -1 })
      .skip(skip)
      .limit(limit);

    return sendSuccess(res, 'Purchase Bills retrieved successfully.', {
      purchaseBills: bills,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    return sendError(res, 'Failed to retrieve Purchase Bills.', { details: error.message }, 500);
  }
};

export const getPurchaseBillById = async (req, res) => {
  try {
    const purchaseBill = await PurchaseBill.findById(req.params.id);
    if (!purchaseBill) {
      return sendError(res, 'Purchase Bill not found.', {}, 404);
    }

    return sendSuccess(res, 'Purchase Bill retrieved successfully.', purchaseBill);
  } catch (error) {
    return sendError(res, 'Failed to fetch Purchase Bill.', { details: error.message }, 500);
  }
};

export const updatePurchaseBill = async (req, res) => {
  try {
    const { vendorName, amount, taxAmount, billNumber, billDate, remarks, status } = req.body;
    
    const purchaseBill = await PurchaseBill.findById(req.params.id);
    if (!purchaseBill) {
      return sendError(res, 'Purchase Bill not found.', {}, 404);
    }

    const updatePayload = {};
    if (vendorName !== undefined) updatePayload.vendorName = vendorName.trim();
    if (amount !== undefined) updatePayload.amount = Number(amount);
    if (taxAmount !== undefined) updatePayload.taxAmount = Number(taxAmount);
    if (billNumber !== undefined) updatePayload.billNumber = billNumber.trim();
    if (billDate !== undefined) updatePayload.billDate = new Date(billDate);
    if (remarks !== undefined) updatePayload.remarks = remarks;
    if (status !== undefined) updatePayload.status = status;

    // Support uploading a new attachment
    if (req.file) {
      try {
        updatePayload.attachmentUrl = await uploadToCloudinary(req.file, 'dts/purchase-bills');
      } catch (uploadErr) {
        return sendError(res, 'Failed to upload new bill attachment.', { details: uploadErr.message }, 500);
      }
    }

    const updated = await PurchaseBill.findByIdAndUpdate(req.params.id, updatePayload, {
      new: true,
      runValidators: true,
    });

    return sendSuccess(res, 'Purchase Bill updated successfully.', updated);
  } catch (error) {
    return sendError(res, 'Failed to update Purchase Bill.', { details: error.message }, 500);
  }
};

export const deletePurchaseBill = async (req, res) => {
  try {
    const purchaseBill = await PurchaseBill.findByIdAndDelete(req.params.id);
    if (!purchaseBill) {
      return sendError(res, 'Purchase Bill not found.', {}, 404);
    }

    return sendSuccess(res, 'Purchase Bill deleted successfully.', {});
  } catch (error) {
    return sendError(res, 'Failed to delete Purchase Bill.', { details: error.message }, 500);
  }
};
