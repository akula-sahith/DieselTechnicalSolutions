import TaxInvoice from '../models/taxinvoice.model.js';
import { sendSuccess, sendError } from '../utils/response.js';
import { calculateEstimateTotals, formatInvoiceNumber, generateNextSequence } from '../utils/financial.utils.js';
import { numberToWords } from '../utils/agreement.utils.js';
import { generatePaymentData, getCompanyBankDetails } from '../utils/payment.utils.js';

const getTaxInvoicePayload = (req) => {
  const rawPayload = req.body?.taxInvoice ?? req.body;
  if (!rawPayload) {
    return null;
  }

  return typeof rawPayload === 'string' ? JSON.parse(rawPayload) : rawPayload;
};

export const createTaxInvoice = async (req, res) => {
  try {
    const invoicePayload = getTaxInvoicePayload(req);

    if (!invoicePayload) {
      return sendError(res, 'Tax Invoice payload is required.', {}, 400);
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

    if (
      items.some(
        (item) =>
          item.taxApplicable &&
          ![0, 0.25, 3, 5, 12, 18, 28, 40].includes(Number(item.gstPercentage))
      )
    ) {
      return sendError(res, 'Invalid GST percentage. Must be one of: 0, 0.25, 3, 5, 12, 18, 28, 40.', {}, 400);
    }

    const totals = calculateEstimateTotals(items);
    const sequence = await generateNextSequence(TaxInvoice, 'invoiceNumber');
    // Payment-related fields removed: invoices are billing-only documents

    const invoiceDocument = {
      invoiceNumber: formatInvoiceNumber(sequence),
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
      subtotal: totals.subtotal,
      totalTax: totals.totalTax,
      totalAmount: totals.totalAmount,
      amountInWords: numberToWords(totals.totalAmount),
      termsAndConditions: invoicePayload.termsAndConditions,
      authorizedSignatureUrl: invoicePayload.authorizedSignatureUrl,
    };

    const taxInvoice = await TaxInvoice.create(invoiceDocument);

    // Upsert customer and append invoice history
    try {
      const { upsertCustomerFromInvoice } = await import('../utils/customer.utils.js');
      await upsertCustomerFromInvoice(taxInvoice.billTo, taxInvoice);
    } catch (e) {
      console.error('Failed to upsert customer from invoice:', e?.message || e);
    }

    const paymentData = await generatePaymentData(totals.totalAmount, `INV-${taxInvoice.invoiceNumber}`);
    const bankDetails = getCompanyBankDetails();

    const responseData = {
      ...taxInvoice.toObject(),
      payment: paymentData,
      bankDetails,
    };

    return sendSuccess(res, 'Tax Invoice created successfully.', responseData, 201);
  } catch (error) {
    if (error instanceof SyntaxError) {
      return sendError(res, 'Invalid JSON payload.', { details: error.message }, 400);
    }

    if (error.code === 11000) {
      return sendError(res, 'Invoice number already exists.', { details: error.message }, 400);
    }

    return sendError(res, 'Failed to create Tax Invoice.', { details: error.message }, 500);
  }
};

export const getTaxInvoices = async (req, res) => {
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

    const [taxInvoices, total] = await Promise.all([
      TaxInvoice.find(query).sort({ createdAt: -1 }).skip(skip).limit(limit).populate('linkedEstimateId', 'estimateNumber'),
      TaxInvoice.countDocuments(query),
    ]);

    const invoicesWithPayment = await Promise.all(
      taxInvoices.map(async (invoice) => {
        const paymentData = await generatePaymentData(invoice.totalAmount, `INV-${invoice.invoiceNumber}`);
        const bankDetails = getCompanyBankDetails();
        return {
          ...invoice.toObject(),
          payment: paymentData,
          bankDetails,
        };
      })
    );

    return sendSuccess(res, 'Tax Invoices retrieved successfully.', {
      taxInvoices: invoicesWithPayment,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    return sendError(res, 'Failed to fetch Tax Invoices.', { details: error.message }, 500);
  }
};

export const getTaxInvoiceById = async (req, res) => {
  try {
    const taxInvoice = await TaxInvoice.findById(req.params.id).populate('linkedEstimateId', 'estimateNumber');

    if (!taxInvoice) {
      return sendError(res, 'Tax Invoice not found.', {}, 404);
    }

    const paymentData = await generatePaymentData(taxInvoice.totalAmount, `INV-${taxInvoice.invoiceNumber}`);
    const bankDetails = getCompanyBankDetails();

    const responseData = {
      ...taxInvoice.toObject(),
      payment: paymentData,
      bankDetails,
    };

    return sendSuccess(res, 'Tax Invoice retrieved successfully.', responseData);
  } catch (error) {
    return sendError(res, 'Failed to fetch Tax Invoice.', { details: error.message }, 500);
  }
};

export const updateTaxInvoice = async (req, res) => {
  try {
    const invoicePayload = getTaxInvoicePayload(req);

    if (!invoicePayload) {
      return sendError(res, 'Tax Invoice payload is required.', {}, 400);
    }

    const taxInvoice = await TaxInvoice.findById(req.params.id);
    if (!taxInvoice) {
      return sendError(res, 'Tax Invoice not found.', {}, 404);
    }

    const items = invoicePayload.items || taxInvoice.items || [];
    if (!Array.isArray(items) || items.length === 0) {
      return sendError(res, 'At least one item is required.', {}, 400);
    }

    const totals = calculateEstimateTotals(items);

    const updatePayload = {
      invoiceDate: invoicePayload.invoiceDate ? new Date(invoicePayload.invoiceDate) : taxInvoice.invoiceDate,
      billTo: {
        customerName: invoicePayload.billTo?.customerName || taxInvoice.billTo.customerName,
        address: invoicePayload.billTo?.address || taxInvoice.billTo.address,
        contactPerson: invoicePayload.billTo?.contactPerson || taxInvoice.billTo.contactPerson,
        contactNumber: invoicePayload.billTo?.contactNumber || taxInvoice.billTo.contactNumber,
        gstinNumber: invoicePayload.billTo?.gstinNumber || taxInvoice.billTo.gstinNumber,
      },
      placeOfSupply: invoicePayload.placeOfSupply || taxInvoice.placeOfSupply,
      transportationDetails: {
        vehicleNumber: invoicePayload.transportationDetails?.vehicleNumber || taxInvoice.transportationDetails.vehicleNumber,
        transportName: invoicePayload.transportationDetails?.transportName || taxInvoice.transportationDetails.transportName,
        lrNumber: invoicePayload.transportationDetails?.lrNumber || taxInvoice.transportationDetails.lrNumber,
        dispatchDetails: invoicePayload.transportationDetails?.dispatchDetails || taxInvoice.transportationDetails.dispatchDetails,
        deliveryDetails: invoicePayload.transportationDetails?.deliveryDetails || taxInvoice.transportationDetails.deliveryDetails,
      },
      items: totals.items,
      subtotal: totals.subtotal,
      totalTax: totals.totalTax,
      totalAmount: totals.totalAmount,
      amountInWords: numberToWords(totals.totalAmount),
      // paymentDetails removed from invoice updates
      termsAndConditions: invoicePayload.termsAndConditions || taxInvoice.termsAndConditions,
      authorizedSignatureUrl: invoicePayload.authorizedSignatureUrl || taxInvoice.authorizedSignatureUrl,
    };

    const updatedInvoice = await TaxInvoice.findByIdAndUpdate(req.params.id, updatePayload, {
      new: true,
      runValidators: true,
    });

    // After update, return updated invoice without payment artifacts
    // Also upsert customer to ensure invoice history stays in sync
    try {
      const { upsertCustomerFromInvoice } = await import('../utils/customer.utils.js');
      await upsertCustomerFromInvoice(updatedInvoice.billTo, updatedInvoice);
    } catch (e) {
      console.error('Failed to upsert customer from invoice:', e?.message || e);
    }

    return sendSuccess(res, 'Tax Invoice updated successfully.', updatedInvoice);
  } catch (error) {
    return sendError(res, 'Failed to update Tax Invoice.', { details: error.message }, 500);
  }
};

export const updatePaymentStatus = async (req, res) => {
  try {
    // Payment updates are no longer supported at invoice level.
    return sendError(res, 'Updating payment status on Tax Invoice is not supported. Use Estimate payment tracking instead.', {}, 400);
  } catch (error) {
    return sendError(res, 'Failed to update payment status.', { details: error.message }, 500);
  }
};

export const deleteTaxInvoice = async (req, res) => {
  try {
    const taxInvoice = await TaxInvoice.findByIdAndDelete(req.params.id);

    if (!taxInvoice) {
      return sendError(res, 'Tax Invoice not found.', {}, 404);
    }

    return sendSuccess(res, 'Tax Invoice deleted successfully.', {});
  } catch (error) {
    return sendError(res, 'Failed to delete Tax Invoice.', { details: error.message }, 500);
  }
};
