import BillingInvoice from '../models/billinginvoice.model.js';
import { sendSuccess, sendError } from '../utils/response.js';
import {
  calculateBillingTotals,
  formatBillingInvoiceNumber,
  generateNextSequence,
} from '../utils/financial.utils.js';
import { numberToWords } from '../utils/agreement.utils.js';
import { generatePaymentData, getCompanyBankDetails } from '../utils/payment.utils.js';

const getBillingInvoicePayload = (req) => {
  const rawPayload = req.body?.billingInvoice ?? req.body;
  if (!rawPayload) {
    return null;
  }

  return typeof rawPayload === 'string' ? JSON.parse(rawPayload) : rawPayload;
};

export const createBillingInvoice = async (req, res) => {
  try {
    const invoicePayload = getBillingInvoicePayload(req);

    if (!invoicePayload) {
      return sendError(res, 'Billing Invoice payload is required.', {}, 400);
    }

    const items = invoicePayload.items || [];
    if (!Array.isArray(items) || items.length === 0) {
      return sendError(res, 'At least one item is required.', {}, 400);
    }

    const requiredCustomerFields = ['customerName', 'address', 'contactNumber'];
    const missingField = requiredCustomerFields.find(
      (field) => !invoicePayload.billTo?.[field]
    );
    if (missingField) {
      return sendError(res, `Customer field "${missingField}" is required.`, {}, 400);
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
      return sendError(res, 'Each item must have a valid name, quantity > 0, and price > 0.', {}, 400);
    }

    const totals = calculateBillingTotals(items);
    const sequence = await generateNextSequence(BillingInvoice, 'invoiceNumber');

    const invoiceDocument = {
      invoiceNumber: formatBillingInvoiceNumber(sequence),
      invoiceDate: invoicePayload.invoiceDate ? new Date(invoicePayload.invoiceDate) : new Date(),
      billTo: {
        customerName: invoicePayload.billTo.customerName,
        address: invoicePayload.billTo.address,
        contactPerson: invoicePayload.billTo.contactPerson || '',
        contactNumber: invoicePayload.billTo.contactNumber,
        gstinNumber: invoicePayload.billTo.gstinNumber || '',
      },
      placeOfSupply: invoicePayload.placeOfSupply || '',
      transportationDetails: {
        vehicleNumber: invoicePayload.transportationDetails?.vehicleNumber || '',
        transportName: invoicePayload.transportationDetails?.transportName || '',
        lrNumber: invoicePayload.transportationDetails?.lrNumber || '',
        dispatchDetails: invoicePayload.transportationDetails?.dispatchDetails || '',
        deliveryDetails: invoicePayload.transportationDetails?.deliveryDetails || '',
      },
      items: totals.items,
      totalAmount: totals.totalAmount,
      amountInWords: numberToWords(totals.totalAmount),
      termsAndConditions: invoicePayload.termsAndConditions,
      authorizedSignatureUrl: invoicePayload.authorizedSignatureUrl,
    };

    const billingInvoice = await BillingInvoice.create(invoiceDocument);

    // Upsert customer and append invoice history
    try {
      const { upsertCustomerFromInvoice } = await import('../utils/customer.utils.js');
      await upsertCustomerFromInvoice(billingInvoice.billTo, billingInvoice);
    } catch (e) {
      console.error('Failed to upsert customer from billing invoice:', e?.message || e);
    }

    const paymentData = await generatePaymentData(totals.totalAmount, `BILL-${billingInvoice.invoiceNumber}`);
    const bankDetails = getCompanyBankDetails();

    const responseData = {
      ...billingInvoice.toObject(),
      payment: paymentData,
      bankDetails,
    };

    return sendSuccess(res, 'Billing Invoice created successfully.', responseData, 201);
  } catch (error) {
    if (error instanceof SyntaxError) {
      return sendError(res, 'Invalid JSON payload.', { details: error.message }, 400);
    }

    if (error.code === 11000) {
      return sendError(res, 'Invoice number already exists.', { details: error.message }, 400);
    }

    return sendError(res, 'Failed to create Billing Invoice.', { details: error.message }, 500);
  }
};

export const getBillingInvoices = async (req, res) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 10));
    const skip = (page - 1) * limit;
    const search = req.query.search || '';
    const customerName = req.query.customerName || '';
    const invoiceNumber = req.query.invoiceNumber || '';
    const dateFrom = req.query.dateFrom || '';
    const dateTo = req.query.dateTo || '';

    const query = {};

    if (search) {
      query.$or = [
        { invoiceNumber: { $regex: search, $options: 'i' } },
        { 'billTo.customerName': { $regex: search, $options: 'i' } },
        { 'billTo.contactNumber': { $regex: search, $options: 'i' } },
      ];
    }

    if (customerName) {
      query['billTo.customerName'] = { $regex: customerName, $options: 'i' };
    }

    if (invoiceNumber) {
      query.invoiceNumber = { $regex: invoiceNumber, $options: 'i' };
    }

    if (dateFrom || dateTo) {
      query.invoiceDate = {};
      if (dateFrom) {
        query.invoiceDate.$gte = new Date(dateFrom);
      }
      if (dateTo) {
        const endDate = new Date(dateTo);
        endDate.setDate(endDate.getDate() + 1);
        query.invoiceDate.$lt = endDate;
      }
    }

    const [billingInvoices, total] = await Promise.all([
      BillingInvoice.find(query).sort({ createdAt: -1 }).skip(skip).limit(limit).populate('linkedEstimateId', 'estimateNumber'),
      BillingInvoice.countDocuments(query),
    ]);

    const invoicesWithPayment = await Promise.all(
      billingInvoices.map(async (invoice) => {
        const paymentData = await generatePaymentData(invoice.totalAmount, `BILL-${invoice.invoiceNumber}`);
        const bankDetails = getCompanyBankDetails();
        return {
          ...invoice.toObject(),
          payment: paymentData,
          bankDetails,
        };
      })
    );

    return sendSuccess(res, 'Billing Invoices retrieved successfully.', {
      billingInvoices: invoicesWithPayment,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    return sendError(res, 'Failed to fetch Billing Invoices.', { details: error.message }, 500);
  }
};

export const getBillingInvoiceById = async (req, res) => {
  try {
    const billingInvoice = await BillingInvoice.findById(req.params.id).populate('linkedEstimateId', 'estimateNumber');

    if (!billingInvoice) {
      return sendError(res, 'Billing Invoice not found.', {}, 404);
    }

    const paymentData = await generatePaymentData(billingInvoice.totalAmount, `BILL-${billingInvoice.invoiceNumber}`);
    const bankDetails = getCompanyBankDetails();

    const responseData = {
      ...billingInvoice.toObject(),
      payment: paymentData,
      bankDetails,
    };

    return sendSuccess(res, 'Billing Invoice retrieved successfully.', responseData);
  } catch (error) {
    return sendError(res, 'Failed to fetch Billing Invoice.', { details: error.message }, 500);
  }
};

export const updateBillingInvoice = async (req, res) => {
  try {
    const invoicePayload = getBillingInvoicePayload(req);

    if (!invoicePayload) {
      return sendError(res, 'Billing Invoice payload is required.', {}, 400);
    }

    const billingInvoice = await BillingInvoice.findById(req.params.id);
    if (!billingInvoice) {
      return sendError(res, 'Billing Invoice not found.', {}, 404);
    }

    const items = invoicePayload.items || billingInvoice.items || [];
    if (!Array.isArray(items) || items.length === 0) {
      return sendError(res, 'At least one item is required.', {}, 400);
    }

    const totals = calculateBillingTotals(items);

    const updatePayload = {
      invoiceDate: invoicePayload.invoiceDate ? new Date(invoicePayload.invoiceDate) : billingInvoice.invoiceDate,
      billTo: {
        customerName: invoicePayload.billTo?.customerName || billingInvoice.billTo.customerName,
        address: invoicePayload.billTo?.address || billingInvoice.billTo.address,
        contactPerson: invoicePayload.billTo?.contactPerson || billingInvoice.billTo.contactPerson,
        contactNumber: invoicePayload.billTo?.contactNumber || billingInvoice.billTo.contactNumber,
        gstinNumber: invoicePayload.billTo?.gstinNumber || billingInvoice.billTo.gstinNumber,
      },
      placeOfSupply: invoicePayload.placeOfSupply || billingInvoice.placeOfSupply,
      transportationDetails: {
        vehicleNumber: invoicePayload.transportationDetails?.vehicleNumber || billingInvoice.transportationDetails.vehicleNumber,
        transportName: invoicePayload.transportationDetails?.transportName || billingInvoice.transportationDetails.transportName,
        lrNumber: invoicePayload.transportationDetails?.lrNumber || billingInvoice.transportationDetails.lrNumber,
        dispatchDetails: invoicePayload.transportationDetails?.dispatchDetails || billingInvoice.transportationDetails.dispatchDetails,
        deliveryDetails: invoicePayload.transportationDetails?.deliveryDetails || billingInvoice.transportationDetails.deliveryDetails,
      },
      items: totals.items,
      totalAmount: totals.totalAmount,
      amountInWords: numberToWords(totals.totalAmount),
      termsAndConditions: invoicePayload.termsAndConditions || billingInvoice.termsAndConditions,
      authorizedSignatureUrl: invoicePayload.authorizedSignatureUrl || billingInvoice.authorizedSignatureUrl,
    };

    const updatedInvoice = await BillingInvoice.findByIdAndUpdate(req.params.id, updatePayload, {
      new: true,
      runValidators: true,
    });

    try {
      const { upsertCustomerFromInvoice } = await import('../utils/customer.utils.js');
      await upsertCustomerFromInvoice(updatedInvoice.billTo, updatedInvoice);
    } catch (e) {
      console.error('Failed to upsert customer from updated billing invoice:', e?.message || e);
    }

    const paymentData = await generatePaymentData(updatedInvoice.totalAmount, `BILL-${updatedInvoice.invoiceNumber}`);
    const bankDetails = getCompanyBankDetails();

    const responseData = {
      ...updatedInvoice.toObject(),
      payment: paymentData,
      bankDetails,
    };

    return sendSuccess(res, 'Billing Invoice updated successfully.', responseData);
  } catch (error) {
    return sendError(res, 'Failed to update Billing Invoice.', { details: error.message }, 500);
  }
};

export const deleteBillingInvoice = async (req, res) => {
  try {
    const billingInvoice = await BillingInvoice.findByIdAndDelete(req.params.id);

    if (!billingInvoice) {
      return sendError(res, 'Billing Invoice not found.', {}, 404);
    }

    return sendSuccess(res, 'Billing Invoice deleted successfully.', {});
  } catch (error) {
    return sendError(res, 'Failed to delete Billing Invoice.', { details: error.message }, 500);
  }
};
