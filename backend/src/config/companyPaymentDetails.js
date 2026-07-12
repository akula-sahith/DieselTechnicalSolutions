/**
 * Company Payment Details Configuration
 *
 * This is the single source of truth for all company payment information.
 * Update these values to match your company's bank and payment details.
 *
 * NOTE: Never allow frontend to modify or send these values.
 * The backend always uses this configuration for generating invoices and payment requests.
 */

const companyPaymentDetails = {
  // Company Information
  companyName: 'Diesel Technical Solutions',

  // Bank Details
  bankName: 'ICICI Bank',
  accountHolderName: 'GPS Technical Services',
  accountNumber: '1234567890',
  ifscCode: 'ICIC0000001',

  // UPI Details
  upiId: '8341999296-2@axl',

  // Contact Information
  gstNumber: '36AEXPS55330IZ1',
  phoneNumber: '+91-8121312253',
  email: 'dieseltechnicalsolutions@zohomail.in',
};

export default companyPaymentDetails;
