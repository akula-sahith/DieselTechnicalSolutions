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
  bankName: 'Federal Bank',
  accountHolderName: 'Diesel Technical Solutions',
  accountNumber: '24780200001898',
  ifscCode: 'FDRL0002478',

  // UPI Details
  upiId: '9491435957@ybl',

  // Contact Information
  gstNumber: '36AEXPS55330IZ1',
  phoneNumber: '+91-8121312253',
  email: 'dieseltechnicalsolutions@zohomail.in',
};

export default companyPaymentDetails;
