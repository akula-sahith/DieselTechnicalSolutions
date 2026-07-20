import Estimate from '../models/estimate.model.js';
import TaxInvoice from '../models/taxinvoice.model.js';
import { sendSuccess, sendError } from '../utils/response.js';
import {
  calculateEstimateTotals,
  formatEstimateNumber,
  formatInvoiceNumber,
  generateNextSequence,
  calculatePaymentDetails,
} from '../utils/financial.utils.js';
import { numberToWords } from '../utils/agreement.utils.js';
import { generatePaymentData, getCompanyBankDetails } from '../utils/payment.utils.js';
import { upsertCustomerFromInvoice, upsertCustomerFromEstimate } from '../utils/customer.utils.js';

const getEstimatePayload = (req) => {
  const rawPayload = req.body?.estimate ?? req.body;
  if (!rawPayload) {
    return null;
  }

  return typeof rawPayload === 'string' ? JSON.parse(rawPayload) : rawPayload;
};

export const createEstimate = async (req, res) => {
  try {
    const estimatePayload = getEstimatePayload(req);

    if (!estimatePayload) {
      return sendError(res, 'Estimate payload is required.', {}, 400);
    }

    const items = estimatePayload.items || [];
    if (!Array.isArray(items) || items.length === 0) {
      return sendError(res, 'At least one item is required.', {}, 400);
    }

    const requiredCustomerFields = ['customerName', 'address', 'contactNumber'];
    const missingField = requiredCustomerFields.find(
      (field) => !estimatePayload.estimateFor?.[field]
    );
    if (missingField) {
      return sendError(
        res,
        `Customer field "${missingField}" is required.`,
        {},
        400
      );
    }

    const invalidItem = items.find(
      (item) =>
        !item.itemName ||
        !item.quantity ||
        item.quantity <= 0 ||
        !item.pricePerUnit ||
        item.pricePerUnit <= 0
    );
    if (invalidItem) {
      return sendError(
        res,
        'Each item must have a valid name, quantity > 0, and price > 0.',
        {},
        400
      );
    }

    if (items.some((item) => item.taxApplicable && ![0, 0.25, 3, 5, 12, 18, 28, 40].includes(Number(item.gstPercentage)))) {
      return sendError(
        res,
        'Invalid GST percentage. Must be one of: 0, 0.25, 3, 5, 12, 18, 28, 40.',
        {},
        400
      );
    }

    const totals = calculateEstimateTotals(items);
    const sequence = await generateNextSequence(Estimate, 'estimateNumber');

    const estimateDocument = {
      estimateNumber: formatEstimateNumber(sequence),
      estimateDate: estimatePayload.estimateDate ? new Date(estimatePayload.estimateDate) : new Date(),
      estimateFor: {
        customerName: estimatePayload.estimateFor.customerName,
        address: estimatePayload.estimateFor.address,
        contactPerson: estimatePayload.estimateFor.contactPerson || '',
        contactNumber: estimatePayload.estimateFor.contactNumber,
        gstinNumber: estimatePayload.estimateFor.gstinNumber || '',
      },
      placeOfSupply: estimatePayload.placeOfSupply || '',
      items: totals.items,
      subtotal: totals.subtotal,
      totalTax: totals.totalTax,
      totalAmount: totals.totalAmount,
      amountInWords: numberToWords(totals.totalAmount),
      termsAndConditions: estimatePayload.termsAndConditions,
      authorizedSignatureUrl: estimatePayload.authorizedSignatureUrl,
      status: 'draft',
    };

    const estimate = await Estimate.create(estimateDocument);

    // Create or update customer record and append estimate history
    try {
      await upsertCustomerFromEstimate(estimate.estimateFor, estimate);
    } catch (e) {
      console.error('Failed to upsert customer from estimate:', e?.message || e);
    }

    // Generate payment data dynamically
    const paymentData = await generatePaymentData(totals.totalAmount, `EST-${estimate.estimateNumber}`);
    const bankDetails = getCompanyBankDetails();

    const responseData = {
      ...estimate.toObject(),
      payment: paymentData,
      bankDetails,
    };

    return sendSuccess(res, 'Estimate created successfully.', responseData, 201);
  } catch (error) {
    if (error instanceof SyntaxError) {
      return sendError(res, 'Invalid JSON payload.', { details: error.message }, 400);
    }

    if (error.code === 11000) {
      return sendError(res, 'Estimate number already exists.', { details: error.message }, 400);
    }

    return sendError(res, 'Failed to create estimate.', { details: error.message }, 500);
  }
};

export const getEstimates = async (req, res) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 10));
    const skip = (page - 1) * limit;
    const search = req.query.search || '';
    const status = req.query.status || '';
    const customerName = req.query.customerName || '';
    const estimateNumber = req.query.estimateNumber || '';
    const dateFrom = req.query.dateFrom || '';
    const dateTo = req.query.dateTo || '';

    const query = {};

    if (search) {
      query.$or = [
        { estimateNumber: { $regex: search, $options: 'i' } },
        { 'estimateFor.customerName': { $regex: search, $options: 'i' } },
        { 'estimateFor.contactNumber': { $regex: search, $options: 'i' } },
      ];
    }

    if (status) {
      query.status = status;
    }

    if (customerName) {
      query['estimateFor.customerName'] = { $regex: customerName, $options: 'i' };
    }

    if (estimateNumber) {
      query.estimateNumber = { $regex: estimateNumber, $options: 'i' };
    }

    if (dateFrom || dateTo) {
      query.estimateDate = {};
      if (dateFrom) {
        query.estimateDate.$gte = new Date(dateFrom);
      }
      if (dateTo) {
        const endDate = new Date(dateTo);
        endDate.setDate(endDate.getDate() + 1);
        query.estimateDate.$lt = endDate;
      }
    }

    const [estimates, total] = await Promise.all([
      Estimate.find(query).sort({ createdAt: -1 }).skip(skip).limit(limit),
      Estimate.countDocuments(query),
    ]);

    // Add payment data and bank details to each estimate
    const estimatesWithPayment = await Promise.all(
      estimates.map(async (estimate) => {
        const paymentData = await generatePaymentData(
          estimate.totalAmount,
          `EST-${estimate.estimateNumber}`
        );
        const bankDetails = getCompanyBankDetails();

        return {
          ...estimate.toObject(),
          payment: paymentData,
          bankDetails,
        };
      })
    );

    return sendSuccess(res, 'Estimates retrieved successfully.', {
      estimates: estimatesWithPayment,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    return sendError(res, 'Failed to fetch estimates.', { details: error.message }, 500);
  }
};

export const getEstimateById = async (req, res) => {
  try {
    const estimate = await Estimate.findById(req.params.id);

    if (!estimate) {
      return sendError(res, 'Estimate not found.', {}, 404);
    }

    const paymentData = await generatePaymentData(estimate.totalAmount, `EST-${estimate.estimateNumber}`);
    const bankDetails = getCompanyBankDetails();

    const responseData = {
      ...estimate.toObject(),
      payment: paymentData,
      bankDetails,
    };

    return sendSuccess(res, 'Estimate retrieved successfully.', responseData);
  } catch (error) {
    return sendError(res, 'Failed to fetch estimate.', { details: error.message }, 500);
  }
};

export const updateEstimate = async (req, res) => {
  try {
    const estimatePayload = getEstimatePayload(req);

    if (!estimatePayload) {
      return sendError(res, 'Estimate payload is required.', {}, 400);
    }

    const estimate = await Estimate.findById(req.params.id);
    if (!estimate) {
      return sendError(res, 'Estimate not found.', {}, 404);
    }

    if (estimate.status === 'converted') {
      return sendError(res, 'Cannot update an estimate that has been converted to invoice.', {}, 400);
    }

    const items = estimatePayload.items || estimate.items || [];
    if (!Array.isArray(items) || items.length === 0) {
      return sendError(res, 'At least one item is required.', {}, 400);
    }

    const totals = calculateEstimateTotals(items);

    const updatePayload = {
      estimateDate: estimatePayload.estimateDate ? new Date(estimatePayload.estimateDate) : estimate.estimateDate,
      estimateFor: {
        customerName: estimatePayload.estimateFor?.customerName || estimate.estimateFor.customerName,
        address: estimatePayload.estimateFor?.address || estimate.estimateFor.address,
        contactPerson: estimatePayload.estimateFor?.contactPerson || estimate.estimateFor.contactPerson,
        contactNumber: estimatePayload.estimateFor?.contactNumber || estimate.estimateFor.contactNumber,
        gstinNumber: estimatePayload.estimateFor?.gstinNumber || estimate.estimateFor.gstinNumber,
      },
      placeOfSupply: estimatePayload.placeOfSupply || estimate.placeOfSupply,
      items: totals.items,
      subtotal: totals.subtotal,
      totalTax: totals.totalTax,
      totalAmount: totals.totalAmount,
      amountInWords: numberToWords(totals.totalAmount),
      termsAndConditions: estimatePayload.termsAndConditions || estimate.termsAndConditions,
      authorizedSignatureUrl: estimatePayload.authorizedSignatureUrl || estimate.authorizedSignatureUrl,
    };

    const updatedEstimate = await Estimate.findByIdAndUpdate(req.params.id, updatePayload, {
      new: true,
      runValidators: true,
    });

    // Update customer record and estimate history
    try {
      await upsertCustomerFromEstimate(updatedEstimate.estimateFor, updatedEstimate);
    } catch (e) {
      console.error('Failed to upsert customer from updated estimate:', e?.message || e);
    }

    const paymentData = await generatePaymentData(updatedEstimate.totalAmount, `EST-${updatedEstimate.estimateNumber}`);
    const bankDetails = getCompanyBankDetails();

    const responseData = {
      ...updatedEstimate.toObject(),
      payment: paymentData,
      bankDetails,
    };

    return sendSuccess(res, 'Estimate updated successfully.', responseData);
  } catch (error) {
    return sendError(res, 'Failed to update estimate.', { details: error.message }, 500);
  }
};

export const deleteEstimate = async (req, res) => {
  try {
    const estimate = await Estimate.findById(req.params.id);
    if (!estimate) {
      return sendError(res, 'Estimate not found.', {}, 404);
    }

    if (estimate.status === 'converted') {
      return sendError(res, 'Cannot delete an estimate that has been converted to invoice.', {}, 400);
    }

    await Estimate.findByIdAndDelete(req.params.id);

    return sendSuccess(res, 'Estimate deleted successfully.', {});
  } catch (error) {
    return sendError(res, 'Failed to delete estimate.', { details: error.message }, 500);
  }
};

export const convertEstimateToInvoice = async (req, res) => {
  try {
    const estimate = await Estimate.findById(req.params.id);
    if (!estimate) {
      return sendError(res, 'Estimate not found.', {}, 404);
    }

    if (estimate.status === 'converted') {
      return sendError(res, 'This estimate has already been converted to an invoice.', {}, 400);
    }

    const payload = req.body?.taxInvoice ?? req.body ?? {};
    const transportationDetails = payload.transportationDetails || {};

    const sequence = await generateNextSequence(TaxInvoice, 'invoiceNumber');

    const invoiceDocument = {
      invoiceNumber: formatInvoiceNumber(sequence),
      invoiceDate: payload.invoiceDate ? new Date(payload.invoiceDate) : new Date(),
      billTo: {
        customerName: estimate.estimateFor.customerName,
        address: estimate.estimateFor.address,
        contactPerson: estimate.estimateFor.contactPerson,
        contactNumber: estimate.estimateFor.contactNumber,
        gstinNumber: estimate.estimateFor.gstinNumber,
      },
      placeOfSupply: estimate.placeOfSupply,
      transportationDetails: {
        vehicleNumber: transportationDetails.vehicleNumber || '',
        transportName: transportationDetails.transportName || '',
        lrNumber: transportationDetails.lrNumber || '',
        dispatchDetails: transportationDetails.dispatchDetails || '',
        deliveryDetails: transportationDetails.deliveryDetails || '',
      },
      items: estimate.items,
      subtotal: estimate.subtotal,
      totalTax: estimate.totalTax,
      totalAmount: estimate.totalAmount,
      amountInWords: estimate.amountInWords,
      termsAndConditions: estimate.termsAndConditions,
      authorizedSignatureUrl: estimate.authorizedSignatureUrl,
      linkedEstimateId: estimate._id,
    };

    const taxInvoice = await TaxInvoice.create(invoiceDocument);

    // Update estimate status to 'converted'
    await Estimate.findByIdAndUpdate(req.params.id, { status: 'converted' });

    // Create or update customer record and append invoice history
    try {
      await upsertCustomerFromInvoice(taxInvoice.billTo, taxInvoice);
    } catch (e) {
      // Non-fatal: log and continue
      console.error('Failed to upsert customer from invoice:', e?.message || e);
    }

    // Return invoice without payment data (invoices are billing-only documents)
    return sendSuccess(
      res,
      'Estimate converted to Tax Invoice successfully.',
      {
        estimate: { _id: estimate._id, status: 'converted' },
        taxInvoice,
      },
      201
    );
  } catch (error) {
    if (error.code === 11000) {
      return sendError(res, 'Invoice number already exists.', { details: error.message }, 400);
    }

    return sendError(res, 'Failed to convert estimate to invoice.', { details: error.message }, 500);
  }
};
