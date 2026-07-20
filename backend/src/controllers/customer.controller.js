import Customer from '../models/customer.model.js';
import Estimate from '../models/estimate.model.js';
import TaxInvoice from '../models/taxinvoice.model.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const getCustomers = async (req, res) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 10));
    const skip = (page - 1) * limit;
    const search = req.query.search || '';

    const query = {};

    if (search) {
      query.$or = [
        { customerName: { $regex: search, $options: 'i' } },
        { companyName: { $regex: search, $options: 'i' } },
        { gstNumber: { $regex: search, $options: 'i' } },
        { mobileNumber: { $regex: search, $options: 'i' } },
      ];
    }

    const [customers, total] = await Promise.all([
      Customer.find(query).sort({ updatedAt: -1 }).skip(skip).limit(limit),
      Customer.countDocuments(query),
    ]);

    return sendSuccess(res, 'Customers retrieved successfully.', {
      customers,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    return sendError(res, 'Failed to fetch customers.', { details: error.message }, 500);
  }
};

export const getCustomerById = async (req, res) => {
  try {
    const customer = await Customer.findById(req.params.id);

    if (!customer) {
      return sendError(res, 'Customer not found.', {}, 404);
    }

    // Find linked estimates and tax invoices for the detail view
    const customerObj = customer.toObject();
    
    // Find matching estimates
    const estimates = await Estimate.find({
      $or: [
        { 'estimateFor.contactNumber': customer.mobileNumber },
        { 'estimateFor.gstinNumber': customer.gstNumber && customer.gstNumber !== '' ? customer.gstNumber : null },
        { 'estimateFor.customerName': customer.customerName, 'estimateFor.address': customer.address }
      ]
    }).sort({ estimateDate: -1 });

    // Find matching tax invoices
    const taxInvoices = await TaxInvoice.find({
      $or: [
        { 'billTo.contactNumber': customer.mobileNumber },
        { 'billTo.gstinNumber': customer.gstNumber && customer.gstNumber !== '' ? customer.gstNumber : null },
        { 'billTo.customerName': customer.customerName, 'billTo.address': customer.address }
      ]
    }).sort({ invoiceDate: -1 });

    customerObj.estimates = estimates;
    customerObj.taxInvoices = taxInvoices;

    return sendSuccess(res, 'Customer details retrieved successfully.', customerObj);
  } catch (error) {
    return sendError(res, 'Failed to fetch customer details.', { details: error.message }, 500);
  }
};
