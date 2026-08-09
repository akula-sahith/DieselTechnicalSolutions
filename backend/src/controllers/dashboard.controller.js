import Estimate from '../models/estimate.model.js';
import TaxInvoice from '../models/taxinvoice.model.js';
import BillingInvoice from '../models/billinginvoice.model.js';
import PurchaseBill from '../models/purchasebill.model.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const getDashboardStats = async (req, res) => {
  try {
    // 1. Estimate Amount Pending: Estimates with status !== 'converted'
    const pendingEstimates = await Estimate.find({ status: { $ne: 'converted' } }, 'totalAmount');
    const estimateAmountPending = pendingEstimates.reduce((sum, doc) => sum + (doc.totalAmount || 0), 0);

    // 2. Revenue Generated: Total amount of all Tax Invoices + Billing Invoices
    const taxInvoices = await TaxInvoice.find({}, 'totalAmount receivedAmount outstandingAmount');
    const billingInvoices = await BillingInvoice.find({}, 'totalAmount receivedAmount outstandingAmount');

    const taxInvoiceRevenue = taxInvoices.reduce((sum, doc) => sum + (doc.totalAmount || 0), 0);
    const billingInvoiceRevenue = billingInvoices.reduce((sum, doc) => sum + (doc.totalAmount || 0), 0);
    const revenueGenerated = Number((taxInvoiceRevenue + billingInvoiceRevenue).toFixed(2));

    // 3. Payment Received: sum of receivedAmount on Tax Invoices + Billing Invoices
    const taxInvoiceReceived = taxInvoices.reduce((sum, doc) => sum + (doc.receivedAmount || 0), 0);
    const billingInvoiceReceived = billingInvoices.reduce((sum, doc) => sum + (doc.receivedAmount || 0), 0);
    const paymentReceived = Number((taxInvoiceReceived + billingInvoiceReceived).toFixed(2));

    // 4. Outstanding Amount: sum of outstandingAmount on Tax Invoices + Billing Invoices
    const taxInvoiceOutstanding = taxInvoices.reduce((sum, doc) => sum + (doc.outstandingAmount || 0), 0);
    const billingInvoiceOutstanding = billingInvoices.reduce((sum, doc) => sum + (doc.outstandingAmount || 0), 0);
    const outstandingAmount = Number((taxInvoiceOutstanding + billingInvoiceOutstanding).toFixed(2));

    // 5. Purchase Bills: sum of all purchase bills amounts
    const purchaseBillsList = await PurchaseBill.find({}, 'amount');
    const purchaseBills = purchaseBillsList.reduce((sum, doc) => sum + (doc.amount || 0), 0);

    const stats = {
      estimateAmountPending: Number(estimateAmountPending.toFixed(2)),
      revenueGenerated,
      paymentReceived,
      outstandingAmount,
      purchaseBills: Number(purchaseBills.toFixed(2)),
    };

    return sendSuccess(res, 'Dashboard statistics fetched successfully.', stats);
  } catch (error) {
    return sendError(res, 'Failed to fetch dashboard statistics.', { details: error.message }, 500);
  }
};
