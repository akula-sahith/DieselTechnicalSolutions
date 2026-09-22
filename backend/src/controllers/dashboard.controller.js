import Estimate from '../models/estimate.model.js';
import TaxInvoice from '../models/taxinvoice.model.js';
import BillingInvoice from '../models/billinginvoice.model.js';
import PurchaseBill from '../models/purchasebill.model.js';
import Report from '../models/report.model.js';
import Agreement from '../models/agreement.model.js';
import DeliveryChallan from '../models/deliverychallan.model.js';
import { sendSuccess, sendError } from '../utils/response.js';

const MONTH_NAMES = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

const formatDateLabel = (date) => {
  const d = new Date(date);
  const day = String(d.getDate()).padStart(2, '0');
  const month = MONTH_NAMES[d.getMonth()].substring(0, 3);
  const year = d.getFullYear();
  return `${day} ${month} ${year}`;
};

export const getDashboardStats = async (req, res) => {
  try {
    // 1. Estimate Amount Pending: Estimates with status !== 'converted'
    const pendingEstimates = await Estimate.find({ status: { $ne: 'converted' } }, 'totalAmount');
    const estimateAmountPending = pendingEstimates.reduce((sum, doc) => sum + (doc.totalAmount || 0), 0);

    // 2. Fetch all source-of-truth documents
    const taxInvoices = await TaxInvoice.find({}, 'invoiceNumber invoiceDate totalAmount receivedAmount outstandingAmount profitDetails paymentStatus billTo createdAt');
    const billingInvoices = await BillingInvoice.find({}, 'invoiceNumber invoiceDate totalAmount receivedAmount outstandingAmount profitDetails paymentStatus billTo createdAt');
    const purchaseBillsList = await PurchaseBill.find({}, 'billNumber billDate vendorName amount taxAmount status createdAt');
    const estimatesList = await Estimate.find({}, 'estimateNumber estimateDate estimateFor totalAmount status createdAt');
    const agreementsList = await Agreement.find({}, 'offerNumber date documentType customerName grandTotal status createdAt');
    const reportsList = await Report.find({}, 'serviceAndCustomer reportType createdAt');
    const challansList = await DeliveryChallan.find({}, 'challanNumber challanDate deliveryChallanFor totalQuantity status createdAt');

    // Total Financial Overview Calculations
    const taxInvoiceRevenue = taxInvoices.reduce((sum, doc) => sum + (doc.totalAmount || 0), 0);
    const billingInvoiceRevenue = billingInvoices.reduce((sum, doc) => sum + (doc.totalAmount || 0), 0);
    const revenueGenerated = Number((taxInvoiceRevenue + billingInvoiceRevenue).toFixed(2));

    const taxInvoiceReceived = taxInvoices.reduce((sum, doc) => sum + (doc.receivedAmount || 0), 0);
    const billingInvoiceReceived = billingInvoices.reduce((sum, doc) => sum + (doc.receivedAmount || 0), 0);
    const paymentReceived = Number((taxInvoiceReceived + billingInvoiceReceived).toFixed(2));

    const taxInvoiceOutstanding = taxInvoices.reduce((sum, doc) => sum + (doc.outstandingAmount || 0), 0);
    const billingInvoiceOutstanding = billingInvoices.reduce((sum, doc) => sum + (doc.outstandingAmount || 0), 0);
    const outstandingAmount = Number((taxInvoiceOutstanding + billingInvoiceOutstanding).toFixed(2));

    const taxInvoiceProfit = taxInvoices.reduce((sum, doc) => sum + (doc.profitDetails?.netProfit || 0), 0);
    const billingInvoiceProfit = billingInvoices.reduce((sum, doc) => sum + (doc.profitDetails?.netProfit || 0), 0);
    const totalProfit = Number((taxInvoiceProfit + billingInvoiceProfit).toFixed(2));

    const purchaseBills = purchaseBillsList.reduce((sum, doc) => sum + (doc.amount || 0), 0);

    // 3. Month-wise Financial Analysis (Past 12 Months)
    const now = new Date();
    const monthlyAnalytics = [];

    for (let i = 0; i < 12; i++) {
      const targetDate = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const year = targetDate.getFullYear();
      const month = targetDate.getMonth() + 1; // 1-indexed

      const monthStart = new Date(year, month - 1, 1, 0, 0, 0, 0);
      const monthEnd = new Date(year, month, 0, 23, 59, 59, 999);

      const mTaxInvoices = taxInvoices.filter(d => d.invoiceDate && new Date(d.invoiceDate) >= monthStart && new Date(d.invoiceDate) <= monthEnd);
      const mBillingInvoices = billingInvoices.filter(d => d.invoiceDate && new Date(d.invoiceDate) >= monthStart && new Date(d.invoiceDate) <= monthEnd);
      const mPurchaseBills = purchaseBillsList.filter(d => d.billDate && new Date(d.billDate) >= monthStart && new Date(d.billDate) <= monthEnd);
      const mEstimates = estimatesList.filter(d => d.estimateDate && new Date(d.estimateDate) >= monthStart && new Date(d.estimateDate) <= monthEnd);
      const mAgreements = agreementsList.filter(d => d.date && new Date(d.date) >= monthStart && new Date(d.date) <= monthEnd);
      const mReports = reportsList.filter(d => {
        const dt = d.serviceAndCustomer?.dateTime || d.createdAt;
        return dt && new Date(dt) >= monthStart && new Date(dt) <= monthEnd;
      });
      const mChallans = challansList.filter(d => d.challanDate && new Date(d.challanDate) >= monthStart && new Date(d.challanDate) <= monthEnd);

      const mRevenue = mTaxInvoices.reduce((s, d) => s + (d.totalAmount || 0), 0) + mBillingInvoices.reduce((s, d) => s + (d.totalAmount || 0), 0);
      const mCosts = mPurchaseBills.reduce((s, d) => s + (d.amount || 0), 0);
      const mProfit = mRevenue - mCosts;

      const totalTransactions = mTaxInvoices.length + mBillingInvoices.length + mPurchaseBills.length + mEstimates.length + mAgreements.length + mReports.length + mChallans.length;

      // Only include months that are either current or have activity
      if (i === 0 || totalTransactions > 0) {
        monthlyAnalytics.push({
          year,
          month,
          monthName: `${MONTH_NAMES[month - 1]} ${year}`,
          revenue: Number(mRevenue.toFixed(2)),
          costs: Number(mCosts.toFixed(2)),
          profit: Number(mProfit.toFixed(2)),
          taxInvoicesCount: mTaxInvoices.length,
          cashInvoicesCount: mBillingInvoices.length,
          estimatesCount: mEstimates.length,
          purchaseBillsCount: mPurchaseBills.length,
          agreementsCount: mAgreements.length,
          reportsCount: mReports.length,
          deliveryChallansCount: mChallans.length,
          totalTransactions,
        });
      }
    }

    // 4. Global Week-wise Analytics (Last 4 Weeks)
    const weeklyAnalytics = [];
    for (let i = 3; i >= 0; i--) {
      const start = new Date(now.getTime() - (i + 1) * 7 * 24 * 60 * 60 * 1000);
      const end = new Date(now.getTime() - i * 7 * 24 * 60 * 60 * 1000);

      const wTaxInvoices = taxInvoices.filter(doc => doc.invoiceDate && new Date(doc.invoiceDate) >= start && new Date(doc.invoiceDate) <= end);
      const wBillingInvoices = billingInvoices.filter(doc => doc.invoiceDate && new Date(doc.invoiceDate) >= start && new Date(doc.invoiceDate) <= end);
      const wReports = reportsList.filter(doc => {
        const dt = doc.serviceAndCustomer?.dateTime || doc.createdAt;
        return dt && new Date(dt) >= start && new Date(dt) <= end;
      });

      const wRev = wTaxInvoices.reduce((s, doc) => s + (doc.totalAmount || 0), 0) + wBillingInvoices.reduce((s, doc) => s + (doc.totalAmount || 0), 0);
      const wProf = wTaxInvoices.reduce((s, doc) => s + (doc.profitDetails?.netProfit || 0), 0) + wBillingInvoices.reduce((s, doc) => s + (doc.profitDetails?.netProfit || 0), 0);

      weeklyAnalytics.push({
        weekLabel: `Week ${4 - i}`,
        startDate: start.toISOString(),
        endDate: end.toISOString(),
        dateRangeLabel: `${formatDateLabel(start)} – ${formatDateLabel(end)}`,
        revenue: Number(wRev.toFixed(2)),
        profit: Number(wProf.toFixed(2)),
        invoicesCount: wTaxInvoices.length + wBillingInvoices.length,
        reportsCount: wReports.length,
      });
    }

    const stats = {
      estimateAmountPending: Number(estimateAmountPending.toFixed(2)),
      revenueGenerated,
      paymentReceived,
      outstandingAmount,
      totalProfit,
      purchaseBills: Number(purchaseBills.toFixed(2)),
      monthlyAnalytics,
      weeklyAnalytics,
    };

    return sendSuccess(res, 'Dashboard statistics fetched successfully.', stats);
  } catch (error) {
    return sendError(res, 'Failed to fetch dashboard statistics.', { details: error.message }, 500);
  }
};

export const getMonthlyDetail = async (req, res) => {
  try {
    const year = Number(req.query.year) || new Date().getFullYear();
    const month = Number(req.query.month) || (new Date().getMonth() + 1);

    const monthStart = new Date(year, month - 1, 1, 0, 0, 0, 0);
    const monthEnd = new Date(year, month, 0, 23, 59, 59, 999);

    const [
      taxInvoices,
      billingInvoices,
      purchaseBills,
      estimates,
      agreements,
      reports,
      deliveryChallans,
    ] = await Promise.all([
      TaxInvoice.find({ invoiceDate: { $gte: monthStart, $lte: monthEnd } }),
      BillingInvoice.find({ invoiceDate: { $gte: monthStart, $lte: monthEnd } }),
      PurchaseBill.find({ billDate: { $gte: monthStart, $lte: monthEnd } }),
      Estimate.find({ estimateDate: { $gte: monthStart, $lte: monthEnd } }),
      Agreement.find({ date: { $gte: monthStart, $lte: monthEnd } }),
      Report.find({
        $or: [
          { 'serviceAndCustomer.dateTime': { $gte: monthStart, $lte: monthEnd } },
          { createdAt: { $gte: monthStart, $lte: monthEnd } },
        ],
      }),
      DeliveryChallan.find({ challanDate: { $gte: monthStart, $lte: monthEnd } }),
    ]);

    // Financial calculations
    const taxInvoiceTotal = taxInvoices.reduce((s, doc) => s + (doc.totalAmount || 0), 0);
    const billingInvoiceTotal = billingInvoices.reduce((s, doc) => s + (doc.totalAmount || 0), 0);
    const totalRevenue = Number((taxInvoiceTotal + billingInvoiceTotal).toFixed(2));

    const purchaseBillsTotal = purchaseBills.reduce((s, doc) => s + (doc.amount || 0), 0);
    const totalCosts = Number(purchaseBillsTotal.toFixed(2));

    const taxInvoiceProfit = taxInvoices.reduce((s, doc) => s + (doc.profitDetails?.netProfit || 0), 0);
    const billingInvoiceProfit = billingInvoices.reduce((s, doc) => s + (doc.profitDetails?.netProfit || 0), 0);
    const netProfit = Number((taxInvoiceProfit > 0 || billingInvoiceProfit > 0 ? taxInvoiceProfit + billingInvoiceProfit : totalRevenue - totalCosts).toFixed(2));

    const estimatesTotal = estimates.reduce((s, doc) => s + (doc.totalAmount || 0), 0);
    const agreementsTotal = agreements.reduce((s, doc) => s + (doc.grandTotal || 0), 0);
    const totalTransactions = taxInvoices.length + billingInvoices.length + purchaseBills.length + estimates.length + agreements.length + reports.length + deliveryChallans.length;

    // Week-wise Analysis for this specific month
    const daysInMonth = new Date(year, month, 0).getDate();
    const weeklyAnalytics = [];
    const weekRanges = [
      { startDay: 1, endDay: 7, label: 'Week 1' },
      { startDay: 8, endDay: 14, label: 'Week 2' },
      { startDay: 15, endDay: 21, label: 'Week 3' },
      { startDay: 22, endDay: 28, label: 'Week 4' },
    ];

    if (daysInMonth > 28) {
      weekRanges.push({ startDay: 29, endDay: daysInMonth, label: 'Week 5' });
    }

    for (const range of weekRanges) {
      const wStart = new Date(year, month - 1, range.startDay, 0, 0, 0, 0);
      const wEnd = new Date(year, month - 1, range.endDay, 23, 59, 59, 999);

      const wTaxInvoices = taxInvoices.filter(d => new Date(d.invoiceDate) >= wStart && new Date(d.invoiceDate) <= wEnd);
      const wBillingInvoices = billingInvoices.filter(d => new Date(d.invoiceDate) >= wStart && new Date(d.invoiceDate) <= wEnd);
      const wPurchaseBills = purchaseBills.filter(d => new Date(d.billDate) >= wStart && new Date(d.billDate) <= wEnd);
      const wEstimates = estimates.filter(d => new Date(d.estimateDate) >= wStart && new Date(d.estimateDate) <= wEnd);
      const wAgreements = agreements.filter(d => new Date(d.date) >= wStart && new Date(d.date) <= wEnd);
      const wReports = reports.filter(d => {
        const dt = d.serviceAndCustomer?.dateTime || d.createdAt;
        return dt && new Date(dt) >= wStart && new Date(dt) <= wEnd;
      });
      const wChallans = deliveryChallans.filter(d => new Date(d.challanDate) >= wStart && new Date(d.challanDate) <= wEnd);

      const wRev = wTaxInvoices.reduce((s, d) => s + (d.totalAmount || 0), 0) + wBillingInvoices.reduce((s, d) => s + (d.totalAmount || 0), 0);
      const wCost = wPurchaseBills.reduce((s, d) => s + (d.amount || 0), 0);
      const wProf = wRev - wCost;
      const docCount = wTaxInvoices.length + wBillingInvoices.length + wPurchaseBills.length + wEstimates.length + wAgreements.length + wReports.length + wChallans.length;

      weeklyAnalytics.push({
        weekLabel: range.label,
        startDate: wStart.toISOString(),
        endDate: wEnd.toISOString(),
        dateRangeLabel: `${formatDateLabel(wStart)} – ${formatDateLabel(wEnd)}`,
        revenue: Number(wRev.toFixed(2)),
        costs: Number(wCost.toFixed(2)),
        profit: Number(wProf.toFixed(2)),
        documentsCount: docCount,
      });
    }

    const detailData = {
      year,
      month,
      monthName: `${MONTH_NAMES[month - 1]} ${year}`,
      monthSummary: {
        totalRevenue,
        totalCosts,
        netProfit,
        totalTransactions,
      },
      revenueBreakdown: {
        taxInvoices: { count: taxInvoices.length, totalAmount: Number(taxInvoiceTotal.toFixed(2)) },
        cashInvoices: { count: billingInvoices.length, totalAmount: Number(billingInvoiceTotal.toFixed(2)) },
        totalRevenue,
      },
      costBreakdown: {
        purchaseBills: { count: purchaseBills.length, totalAmount: Number(purchaseBillsTotal.toFixed(2)) },
        totalCosts,
      },
      documentAnalysis: {
        serviceReports: { count: reports.length, totalAmount: 0 },
        agreements: { count: agreements.length, totalAmount: Number(agreementsTotal.toFixed(2)) },
        estimates: { count: estimates.length, totalAmount: Number(estimatesTotal.toFixed(2)) },
        taxInvoices: { count: taxInvoices.length, totalAmount: Number(taxInvoiceTotal.toFixed(2)) },
        cashInvoices: { count: billingInvoices.length, totalAmount: Number(billingInvoiceTotal.toFixed(2)) },
        purchaseBills: { count: purchaseBills.length, totalAmount: Number(purchaseBillsTotal.toFixed(2)) },
        deliveryChallans: { count: deliveryChallans.length, totalAmount: 0 },
      },
      weeklyAnalytics,
    };

    return sendSuccess(res, 'Monthly financial analysis fetched successfully.', detailData);
  } catch (error) {
    return sendError(res, 'Failed to fetch monthly financial analysis.', { details: error.message }, 500);
  }
};

export const getWeekDocuments = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    if (!startDate || !endDate) {
      return sendError(res, 'startDate and endDate parameters are required.', {}, 400);
    }

    const start = new Date(startDate);
    const end = new Date(endDate);

    const [
      taxInvoices,
      billingInvoices,
      estimates,
      agreements,
      reports,
      purchaseBills,
      deliveryChallans,
    ] = await Promise.all([
      TaxInvoice.find({ invoiceDate: { $gte: start, $lte: end } }),
      BillingInvoice.find({ invoiceDate: { $gte: start, $lte: end } }),
      Estimate.find({ estimateDate: { $gte: start, $lte: end } }),
      Agreement.find({ date: { $gte: start, $lte: end } }),
      Report.find({
        $or: [
          { 'serviceAndCustomer.dateTime': { $gte: start, $lte: end } },
          { createdAt: { $gte: start, $lte: end } },
        ],
      }),
      PurchaseBill.find({ billDate: { $gte: start, $lte: end } }),
      DeliveryChallan.find({ challanDate: { $gte: start, $lte: end } }),
    ]);

    const documents = [];

    // 1. Tax Invoices
    for (const inv of taxInvoices) {
      documents.push({
        id: inv._id,
        documentNumber: inv.invoiceNumber || 'INV-Pending',
        documentType: 'Tax Invoice',
        customerName: inv.billTo?.customerName || 'N/A',
        date: inv.invoiceDate,
        amount: inv.totalAmount || 0,
        status: inv.paymentStatus?.replaceAll('_', ' ').toUpperCase() || 'UNPAID',
        rawDocument: inv,
      });
    }

    // 2. Cash Invoices
    for (const inv of billingInvoices) {
      documents.push({
        id: inv._id,
        documentNumber: inv.invoiceNumber || 'BILL-Pending',
        documentType: 'Cash Invoice',
        customerName: inv.billTo?.customerName || 'N/A',
        date: inv.invoiceDate,
        amount: inv.totalAmount || 0,
        status: inv.paymentStatus?.replaceAll('_', ' ').toUpperCase() || 'UNPAID',
        rawDocument: inv,
      });
    }

    // 3. Estimates
    for (const est of estimates) {
      documents.push({
        id: est._id,
        documentNumber: est.estimateNumber || 'EST-Pending',
        documentType: 'Estimate',
        customerName: est.estimateFor?.customerName || 'N/A',
        date: est.estimateDate,
        amount: est.totalAmount || 0,
        status: est.status?.toUpperCase() || 'DRAFT',
        rawDocument: est,
      });
    }

    // 4. Agreements
    for (const agr of agreements) {
      documents.push({
        id: agr._id,
        documentNumber: agr.offerNumber || 'Offer-Pending',
        documentType: agr.documentType || 'Agreement',
        customerName: agr.customerName || 'N/A',
        date: agr.date,
        amount: agr.grandTotal || 0,
        status: agr.status?.toUpperCase() || 'SUBMITTED',
        rawDocument: agr,
      });
    }

    // 5. Service Reports
    for (const rep of reports) {
      documents.push({
        id: rep._id,
        documentNumber: rep.serviceAndCustomer?.jobRef || 'Report',
        documentType: 'Service Report',
        customerName: rep.serviceAndCustomer?.customerName || 'N/A',
        date: rep.serviceAndCustomer?.dateTime || rep.createdAt,
        amount: null,
        status: rep.status?.toUpperCase() || 'SUBMITTED',
        rawDocument: rep,
      });
    }

    // 6. Purchase Bills
    for (const bill of purchaseBills) {
      documents.push({
        id: bill._id,
        documentNumber: bill.billNumber || 'Bill-Pending',
        documentType: 'Purchase Bill',
        customerName: bill.vendorName || 'N/A',
        date: bill.billDate,
        amount: bill.amount || 0,
        status: bill.status?.toUpperCase() || 'PENDING',
        rawDocument: bill,
      });
    }

    // 7. Delivery Challans
    for (const dc of deliveryChallans) {
      documents.push({
        id: dc._id,
        documentNumber: dc.challanNumber || 'Challan-Pending',
        documentType: 'Delivery Challan',
        customerName: dc.deliveryChallanFor?.customerName || 'N/A',
        date: dc.challanDate,
        amount: null,
        status: dc.status?.toUpperCase() || 'ISSUED',
        rawDocument: dc,
      });
    }

    // Sort descending by date
    documents.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

    const dateRangeLabel = `${formatDateLabel(start)} – ${formatDateLabel(end)}`;

    return sendSuccess(res, 'Week documents fetched successfully.', {
      dateRangeLabel,
      startDate: start.toISOString(),
      endDate: end.toISOString(),
      totalCount: documents.length,
      documents,
    });
  } catch (error) {
    return sendError(res, 'Failed to fetch week documents.', { details: error.message }, 500);
  }
};
