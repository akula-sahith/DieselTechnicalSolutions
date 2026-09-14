import Estimate from '../models/estimate.model.js';
import TaxInvoice from '../models/taxinvoice.model.js';
import BillingInvoice from '../models/billinginvoice.model.js';
import PurchaseBill from '../models/purchasebill.model.js';
import Report from '../models/report.model.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const getDashboardStats = async (req, res) => {
  try {
    // 1. Estimate Amount Pending: Estimates with status !== 'converted'
    const pendingEstimates = await Estimate.find({ status: { $ne: 'converted' } }, 'totalAmount');
    const estimateAmountPending = pendingEstimates.reduce((sum, doc) => sum + (doc.totalAmount || 0), 0);

    // 2. Revenue Generated: Total amount of all Tax Invoices + Billing Invoices
    const taxInvoices = await TaxInvoice.find({}, 'totalAmount receivedAmount outstandingAmount profitDetails createdAt');
    const billingInvoices = await BillingInvoice.find({}, 'totalAmount receivedAmount outstandingAmount profitDetails createdAt');
    const allReports = await Report.find({}, 'createdAt');

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

    // 5. Total Net Profit: sum of netProfit from profitDetails on Tax Invoices + Billing Invoices
    const taxInvoiceProfit = taxInvoices.reduce((sum, doc) => sum + (doc.profitDetails?.netProfit || 0), 0);
    const billingInvoiceProfit = billingInvoices.reduce((sum, doc) => sum + (doc.profitDetails?.netProfit || 0), 0);
    const totalProfit = Number((taxInvoiceProfit + billingInvoiceProfit).toFixed(2));

    // 6. Purchase Bills: sum of all purchase bills amounts
    const purchaseBillsList = await PurchaseBill.find({}, 'amount');
    const purchaseBills = purchaseBillsList.reduce((sum, doc) => sum + (doc.amount || 0), 0);

    // 7. Week-wise Analytics (Last 4 Weeks)
    const now = new Date();
    const weeklyAnalytics = [];

    for (let i = 3; i >= 0; i--) {
      const start = new Date(now.getTime() - (i + 1) * 7 * 24 * 60 * 60 * 1000);
      const end = new Date(now.getTime() - i * 7 * 24 * 60 * 60 * 1000);

      const weekTaxInvoices = taxInvoices.filter(doc => doc.createdAt && new Date(doc.createdAt) >= start && new Date(doc.createdAt) <= end);
      const weekBillingInvoices = billingInvoices.filter(doc => doc.createdAt && new Date(doc.createdAt) >= start && new Date(doc.createdAt) <= end);
      const weekReports = allReports.filter(doc => doc.createdAt && new Date(doc.createdAt) >= start && new Date(doc.createdAt) <= end);

      const weekRev = weekTaxInvoices.reduce((s, doc) => s + (doc.totalAmount || 0), 0) + weekBillingInvoices.reduce((s, doc) => s + (doc.totalAmount || 0), 0);
      const weekProf = weekTaxInvoices.reduce((s, doc) => s + (doc.profitDetails?.netProfit || 0), 0) + weekBillingInvoices.reduce((s, doc) => s + (doc.profitDetails?.netProfit || 0), 0);

      weeklyAnalytics.push({
        weekLabel: `Week ${4 - i}`,
        startDate: start.toISOString(),
        endDate: end.toISOString(),
        revenue: Number(weekRev.toFixed(2)),
        profit: Number(weekProf.toFixed(2)),
        invoicesCount: weekTaxInvoices.length + weekBillingInvoices.length,
        reportsCount: weekReports.length,
      });
    }

    const stats = {
      estimateAmountPending: Number(estimateAmountPending.toFixed(2)),
      revenueGenerated,
      paymentReceived,
      outstandingAmount,
      totalProfit,
      purchaseBills: Number(purchaseBills.toFixed(2)),
      weeklyAnalytics,
    };

    return sendSuccess(res, 'Dashboard statistics fetched successfully.', stats);
  } catch (error) {
    return sendError(res, 'Failed to fetch dashboard statistics.', { details: error.message }, 500);
  }
};
