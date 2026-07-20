import Customer from '../models/customer.model.js';

export async function upsertCustomerFromInvoice(billTo, taxInvoice) {
  if (!billTo || !taxInvoice) return null;

  const searchConditions = [];
  if (billTo.gstinNumber) searchConditions.push({ gstNumber: billTo.gstinNumber });
  if (billTo.contactNumber) searchConditions.push({ mobileNumber: billTo.contactNumber });
  if (billTo.customerName && billTo.address) searchConditions.push({ customerName: billTo.customerName, address: billTo.address });

  let customer = null;
  if (searchConditions.length > 0) {
    customer = await Customer.findOne({ $or: searchConditions });
  }

  const invoiceEntry = {
    invoiceNumber: taxInvoice.invoiceNumber,
    invoiceDate: taxInvoice.invoiceDate || new Date(),
    invoiceAmount: taxInvoice.totalAmount || 0,
  };

  if (customer) {
    // Update basic fields
    customer.customerName = billTo.customerName || customer.customerName;
    customer.companyName = billTo.companyName || customer.companyName || billTo.customerName;
    customer.gstNumber = billTo.gstinNumber || customer.gstNumber;
    customer.contactPerson = billTo.contactPerson || customer.contactPerson;
    customer.mobileNumber = billTo.contactNumber || customer.mobileNumber;
    customer.email = billTo.email || customer.email;
    customer.address = billTo.address || customer.address;

    // Append invoice history if not present
    const exists = (customer.invoiceHistory || []).some(h => h.invoiceNumber === invoiceEntry.invoiceNumber);
    if (!exists) customer.invoiceHistory.push(invoiceEntry);

    await customer.save();
    return customer;
  }

  // Create new customer
  const newCustomer = await Customer.create({
    customerName: billTo.customerName || 'Unknown',
    companyName: billTo.companyName || billTo.customerName || '',
    gstNumber: billTo.gstinNumber || '',
    contactPerson: billTo.contactPerson || '',
    mobileNumber: billTo.contactNumber || '',
    email: billTo.email || '',
    address: billTo.address || '',
    invoiceHistory: [invoiceEntry],
  });

  return newCustomer;
}

export async function upsertCustomerFromEstimate(estimateFor, estimate) {
  if (!estimateFor || !estimate) return null;

  const searchConditions = [];
  if (estimateFor.gstinNumber) searchConditions.push({ gstNumber: estimateFor.gstinNumber });
  if (estimateFor.contactNumber) searchConditions.push({ mobileNumber: estimateFor.contactNumber });
  if (estimateFor.customerName && estimateFor.address) searchConditions.push({ customerName: estimateFor.customerName, address: estimateFor.address });

  let customer = null;
  if (searchConditions.length > 0) {
    customer = await Customer.findOne({ $or: searchConditions });
  }

  const estimateEntry = {
    estimateNumber: estimate.estimateNumber,
    estimateDate: estimate.estimateDate || new Date(),
    estimateAmount: estimate.totalAmount || 0,
  };

  if (customer) {
    // Update basic fields
    customer.customerName = estimateFor.customerName || customer.customerName;
    customer.companyName = estimateFor.companyName || customer.companyName || estimateFor.customerName;
    customer.gstNumber = estimateFor.gstinNumber || customer.gstNumber;
    customer.contactPerson = estimateFor.contactPerson || customer.contactPerson;
    customer.mobileNumber = estimateFor.contactNumber || customer.mobileNumber;
    customer.email = estimateFor.email || customer.email;
    customer.address = estimateFor.address || customer.address;

    // Append estimate history if not present
    const exists = (customer.estimateHistory || []).some(h => h.estimateNumber === estimateEntry.estimateNumber);
    if (!exists) customer.estimateHistory.push(estimateEntry);

    await customer.save();
    return customer;
  }

  // Create new customer
  const newCustomer = await Customer.create({
    customerName: estimateFor.customerName || 'Unknown',
    companyName: estimateFor.companyName || estimateFor.customerName || '',
    gstNumber: estimateFor.gstinNumber || '',
    contactPerson: estimateFor.contactPerson || '',
    mobileNumber: estimateFor.contactNumber || '',
    email: estimateFor.email || '',
    address: estimateFor.address || '',
    estimateHistory: [estimateEntry],
  });

  return newCustomer;
}

export default { upsertCustomerFromInvoice, upsertCustomerFromEstimate };
